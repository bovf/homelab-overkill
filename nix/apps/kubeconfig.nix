{ nixpkgs }:
{
  mkKubeconfigApp = system: enabledNodes:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      lib  = nixpkgs.lib;
    in
    {
      type = "app";
      program = toString (pkgs.writeShellScript "kubeconfig" ''
        set -euo pipefail
        node_target="''${1:-}"

        list_nodes() {
          echo "Available node targets:" >&2
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: _:
            ''echo "  ${name}-local" >&2''
            + "\n" +
            ''echo "  ${name}-remote" >&2''
          ) enabledNodes)}
        }

        ensure_arg() {
          if [ -z "''${node_target:-}" ]; then
            echo "Error: Missing NODE_TARGET (e.g., engineer-local or engineer-remote)" >&2
            list_nodes
            exit 1
          fi
        }

        parse_node_target() {
          local target="$1"
          if [[ "$target" == *"-local" ]]; then
            node="''${target%-local}"
            mode="local"
          elif [[ "$target" == *"-remote" ]]; then
            node="''${target%-remote}"
            mode="remote"
          else
            echo "Error: Invalid target format '$target'. Use <node>-local or <node>-remote" >&2
            list_nodes
            exit 1
          fi
        }

        node=""
        mode=""

        case "''${node_target}" in
          help|--help|-h)
            cat >&2 <<EOF
        Usage: eval \$(nix run .#kubeconfig -- <NODE_TARGET>)

        Fetches the kubeconfig from a k3s node via SSH, rewrites the server
        address for local or remote access, and prints an export statement.

        NODE_TARGET format:
          <node>-local   Rewrite server to node LAN IP (direct access)
          <node>-remote  Rewrite server to Pangolin domain/port (from SOPS secrets)

        Examples:
          eval \$(nix run .#kubeconfig -- engineer-local)
          eval \$(nix run .#kubeconfig -- engineer-remote)

        The kubeconfig is cached at .cache/kubeconfig/<node>.yaml
        EOF
            list_nodes
            exit 0
            ;;
          *)
            ensure_arg
            parse_node_target "''${node_target}"
            ;;
        esac

        export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

        SECRETS_FILE=""
        if [ -f "secrets/secrets.yaml" ] && command -v sops >/dev/null 2>&1; then
          tmpdir="''${TMPDIR:-/tmp}"
          SECRETS_FILE="$(mktemp "$tmpdir/dobryops-kubeconfig-secrets.XXXXXX")"
          if sops --decrypt secrets/secrets.yaml >"$SECRETS_FILE" 2>/dev/null; then
            echo "Decrypted secrets for kubeconfig" >&2
          else
            echo "Warning: could not decrypt secrets/secrets.yaml (remote mode may fail)" >&2
            rm -f "$SECRETS_FILE"
            SECRETS_FILE=""
          fi
        fi

        get_secret() {
          local key="$1"
          local default="$2"
          if [ -z "$SECRETS_FILE" ] || ! command -v ${pkgs.yq-go}/bin/yq >/dev/null 2>&1; then
            printf "%s" "$default"
            return
          fi
          local value
          value="$(${pkgs.yq-go}/bin/yq -r ".$key // \"\"" "$SECRETS_FILE" 2>/dev/null || true)"
          if [ -n "$value" ] && [ "$value" != "null" ]; then
            printf "%s" "$value"
          else
            printf "%s" "$default"
          fi
        }

        kube_host=""
        kube_port="6443"

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: node:
          let
            k8sApiDomainKey = node.k8sApiDomainSecretKey or "";
            k8sApiPortKey   = node.k8sApiPortSecretKey or "";
          in ''
            if [ "$node" = "${name}" ]; then
              if [ "$mode" = "local" ]; then
                kube_host="${node.ip}"
                kube_port="6443"
              else
                kube_host="$(get_secret "${k8sApiDomainKey}" "${node.domain}")"
                kube_port="$(get_secret "${k8sApiPortKey}" "6443")"
              fi
            fi
          ''
        ) enabledNodes)}

        if [ -z "$kube_host" ]; then
          echo "Error: Unknown node '$node'" >&2
          list_nodes
          [ -n "$SECRETS_FILE" ] && rm -f "$SECRETS_FILE"
          exit 1
        fi

        echo "Fetching kubeconfig from $node_target..." >&2
        raw_kubeconfig="$(ssh "''${node_target}" cat /etc/rancher/k3s/k3s.yaml)" || {
          echo "Error: Failed to fetch kubeconfig via SSH from $node_target" >&2
          [ -n "$SECRETS_FILE" ] && rm -f "$SECRETS_FILE"
          exit 1
        }

        rewritten="$(echo "$raw_kubeconfig" | ${pkgs.yq-go}/bin/yq \
          ".clusters[0].cluster.server = \"https://''${kube_host}:''${kube_port}\"")"

        mkdir -p .cache/kubeconfig
        kubeconfig_path="$PWD/.cache/kubeconfig/''${node}.yaml"
        echo "$rewritten" > "$kubeconfig_path"

        [ -n "$SECRETS_FILE" ] && rm -f "$SECRETS_FILE"

        echo "Kubeconfig for $node ($mode) written to $kubeconfig_path" >&2
        echo "Server: https://''${kube_host}:''${kube_port}" >&2
        echo "export KUBECONFIG=$kubeconfig_path"
      '');
    };
}
