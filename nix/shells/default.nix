{
  pkgs,
  enabledNodes,
  ...
}: let
  # nixpkgs currently has a kubernetes-helm 4.2.0 checkPhase regression on
  # Darwin where a substituted test file no longer exists. The shell only needs
  # the helm CLI, so keep the package usable while upstream catches up.
  kubernetesHelm = pkgs.kubernetes-helm.overrideAttrs (_: {
    doCheck = false;
  });

  sshWrapper = pkgs.writeShellScriptBin "ssh" ''
    set -euo pipefail
    if [ -n "''${SSH_CONFIG_FILE:-}" ]; then
      exec ${pkgs.openssh}/bin/ssh -F "$SSH_CONFIG_FILE" "$@"
    else
      exec ${pkgs.openssh}/bin/ssh "$@"
    fi
  '';

  preCommitHook = pkgs.writeShellScript "homelab-pre-commit" ''
    set -euo pipefail
    cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
    mapfile -t files < <(${pkgs.git}/bin/git diff --cached --name-only --diff-filter=ACMR -- '*.nix')
    [ "''${#files[@]}" -eq 0 ] && exit 0
    exec nix run .#fmt -- --check "''${files[@]}"
  '';

  prePushHook = pkgs.writeShellScript "homelab-pre-push" ''
    set -e
    echo "→ pre-push: gitleaks secret scan" >&2
    ${pkgs.gitleaks}/bin/gitleaks git . --no-banner --redact --exit-code 1
  '';
in {
  default = pkgs.mkShell {
    packages =
      [
        sshWrapper
      ]
      ++ (with pkgs;
        [
          kubectl
          kubernetesHelm
          k9s
          sops
          age
          ssh-to-age
          bitwarden-cli
          jq
          yq-go
          curl
          wget
          git
          vim
          nixos-anywhere
          nixos-rebuild-ng
          alejandra
          gitleaks
          trufflehog
        ]
        ++ lib.optionals stdenv.isLinux [iproute2]);

    shellHook = ''
      set -euo pipefail

      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

      if [ -d .git ]; then
        if [ ! -e .git/hooks/pre-commit ] || [ -L .git/hooks/pre-commit ]; then
          ln -sf "${preCommitHook}" .git/hooks/pre-commit
        else
          echo "Existing manual pre-commit hook left untouched: .git/hooks/pre-commit"
        fi

        if [ ! -e .git/hooks/pre-push ] || [ -L .git/hooks/pre-push ]; then
          ln -sf "${prePushHook}" .git/hooks/pre-push
        else
          echo "Existing manual pre-push hook left untouched: .git/hooks/pre-push"
        fi
      fi

      # Silence Node DEP0040 (built-in `punycode` deprecation) emitted by
      # bitwarden-cli's transitive deps. Cosmetic only; does not affect bw.
      export NODE_OPTIONS="''${NODE_OPTIONS:-} --disable-warning=DEP0040"

      SSH_CONFIG_DIR="$PWD/.cache/ssh"
      mkdir -p "$SSH_CONFIG_DIR"
      export SSH_CONFIG_FILE="$SSH_CONFIG_DIR/config"
      export NIX_SSHOPTS="-F $SSH_CONFIG_FILE"

      {
        if [ -f "$HOME/.ssh/config" ]; then
          echo "Include $HOME/.ssh/config"
          echo
        fi
        echo "# === DobryOps Homelab Nodes ==="
        echo
      } >"$SSH_CONFIG_FILE"

      # Node addresses / ssh identity live encrypted in SOPS (nodes: block)
      # and are cached locally in .cache/nodes.json — the repo is public, so
      # none of them appear in the flake. Bootstrap the cache on first shell
      # entry when the age key is available.
      NODES_JSON=".cache/nodes.json"
      ensure_nodes_cache() {
        if [ -f "$NODES_JSON" ]; then
          return 0
        fi
        if [ -f "secrets/secrets.yaml" ] && command -v sops >/dev/null 2>&1; then
          local nodes_yaml
          if nodes_yaml="$(sops --decrypt --extract '["nodes"]' secrets/secrets.yaml 2>/dev/null)"; then
            mkdir -p .cache
            (umask 077 && printf "%s\n" "$nodes_yaml" | ${pkgs.yq-go}/bin/yq -o=json '.' >"$NODES_JSON")
            echo "Bootstrapped $NODES_JSON from SOPS"
            return 0
          fi
        fi
        echo "Warning: $NODES_JSON missing and SOPS bootstrap failed." >&2
        echo "  Node IPs/identity are unavailable — run: nix run .#bootstrap" >&2
        return 1
      }
      ensure_nodes_cache || true

      node_meta() {
        local filter="$1"
        local default="$2"
        local value
        if [ ! -f "$NODES_JSON" ]; then
          printf "%s" "$default"
          return
        fi
        value="$(${pkgs.jq}/bin/jq -r "$filter // empty" "$NODES_JSON" 2>/dev/null || true)"
        if [ -n "$value" ]; then
          printf "%s" "$value"
        else
          printf "%s" "$default"
        fi
      }

      # SECURITY: resolve only specific scalar SSH fields from SOPS. Never
      # decrypt the full file to a temp path during shell startup, never look up
      # an empty key, and never write unvalidated extracted values into the SSH
      # config. This keeps engineer-remote dynamic without risking whole-file
      # plaintext output in the prompt.
      secret_extract_path() {
        local key="$1"
        local old_ifs part path

        if [ -z "$key" ]; then
          return 1
        fi

        old_ifs="$IFS"
        IFS='.'
        path=""
        for part in $key; do
          case "$part" in
            ""|*[!A-Za-z0-9_-]*)
              IFS="$old_ifs"
              return 1
              ;;
          esac
          path="$path[\"$part\"]"
        done
        IFS="$old_ifs"

        if [ -z "$path" ]; then
          return 1
        fi

        printf "%s" "$path"
      }

      get_secret_scalar() {
        local key="$1"
        local default="$2"
        local path value

        if [ -z "$key" ] || [ ! -f "secrets/secrets.yaml" ] || ! command -v sops >/dev/null 2>&1; then
          printf "%s" "$default"
          return
        fi

        if ! path="$(secret_extract_path "$key")"; then
          printf "%s" "$default"
          return
        fi

        value="$(sops --decrypt --extract "$path" secrets/secrets.yaml 2>/dev/null || true)"
        if [ -z "$value" ] || [ "$value" = "null" ]; then
          printf "%s" "$default"
        else
          printf "%s" "$value"
        fi
      }

      sanitize_ssh_host() {
        local value="$1"
        local default="$2"

        if printf "%s" "$value" | ${pkgs.gnugrep}/bin/grep -Eq '^[A-Za-z0-9_.:-]+$'; then
          printf "%s" "$value"
        else
          printf "%s" "$default"
        fi
      }

      sanitize_ssh_port() {
        local value="$1"
        local default="$2"

        if printf "%s" "$value" | ${pkgs.gnugrep}/bin/grep -Eq '^[0-9]+$'; then
          printf "%s" "$value"
        else
          printf "%s" "$default"
        fi
      }

      # Build node summary lines in a bash variable
      NODE_SUMMARIES=""

      # Generate per-node SSH config. Addresses and identity come from
      # .cache/nodes.json (bootstrapped from SOPS) plus safe scalar secret
      # lookups — never from the public flake metadata.
      ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (
          name: node: let
            localEnabled = node.localTarget or true;
            remoteEnabled = node.remoteTarget or true;
            localPort = toString (node.localPort or 22);
            remotePortDefault = toString (node.remotePort or (node.localPort or 22));
            remoteHostKey = node.remoteHostSecretKey or "";
            remotePortKey = node.remotePortSecretKey or "";
            sshAliases = node.sshAliases or [];
            remoteHostAliases = pkgs.lib.concatStringsSep " " (["${name}-remote"] ++ sshAliases);
          in ''
            # ${name}
            # NOTE: plain assignments on purpose — this block is eval'd at the
            # shell top level, where `local` is a hard error under `set -e`.
            {
              local_ip="$(node_meta '.["${name}"].ip' "")"
              local_port="${localPort}"
              ssh_user="$(node_meta '.ssh_user' "root")"

              default_remote_host="$local_ip"
              default_remote_port="${remotePortDefault}"

              remote_host="$(sanitize_ssh_host "$(get_secret_scalar "${remoteHostKey}" "$default_remote_host")" "$default_remote_host")"
              remote_port="$(sanitize_ssh_port "$(get_secret_scalar "${remotePortKey}" "$default_remote_port")" "$default_remote_port")"

              # Resolve SSH identity file at runtime
              identity_line=""
              configured_id="$(node_meta '.ssh_identity_file' "")"
              user_id="$HOME/.ssh/$USER"

              if [ -n "$configured_id" ]; then
                eval configured_id="$configured_id"  # expand ~ and vars
              fi

              if [ -n "$configured_id" ] && [ -f "$configured_id" ]; then
                identity_line="  IdentityFile $configured_id"
              elif [ -f "$user_id" ]; then
                identity_line="  IdentityFile $user_id"
              else
                echo "Warning: No SSH identity file found for ${name}" >&2
                echo "  tried: nodes.json ssh_identity_file and ~/.ssh/$USER" >&2
                echo "  SSH connections to ${name} may require a password" >&2
              fi

              # Append actual values to summary
              NODE_SUMMARIES="$NODE_SUMMARIES"'  '"${name} - ${node.role}/${node.nodeType}"$'\n'
              ${pkgs.lib.optionalString localEnabled ''
              [ -n "$local_ip" ] && NODE_SUMMARIES="$NODE_SUMMARIES"'    local:  '"$local_ip:$local_port  (ssh ${name}-local)"$'\n'
            ''}
              ${pkgs.lib.optionalString remoteEnabled ''
              [ -n "$remote_host" ] && NODE_SUMMARIES="$NODE_SUMMARIES"'    remote: '"$remote_host:$remote_port  (ssh ${name}-remote)"$'\n'
            ''}

              # Write SSH config
              {
                echo "# === ${name} ==="
                ${pkgs.lib.optionalString localEnabled ''
              if [ -n "$local_ip" ]; then
                echo "Host ${name}-local"
                echo "  HostName $local_ip"
                echo "  Port $local_port"
                echo "  User $ssh_user"
                [ -n "$identity_line" ] && echo "$identity_line"
                echo "  StrictHostKeyChecking accept-new"
                echo "  ConnectTimeout 10"
                echo ""
              fi
            ''}
                ${pkgs.lib.optionalString remoteEnabled ''
              if [ -n "$remote_host" ]; then
                echo "Host ${remoteHostAliases}"
                echo "  HostName $remote_host"
                echo "  Port $remote_port"
                echo "  User $ssh_user"
                [ -n "$identity_line" ] && echo "$identity_line"
                echo "  StrictHostKeyChecking accept-new"
                echo "  ConnectTimeout 10"
                echo "  ServerAliveInterval 60"
                echo ""
              fi
            ''}
              } >>"$SSH_CONFIG_FILE"
            }
          ''
        )
        enabledNodes)}

      # --- SSH Keys Status Report ---
      KEYS_MISSING=""
      KEYS_LOADED=""

      ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (
          name: node: ''
            # Resolve actual identity for ${name} (same logic as SSH config above)
            key_path=""
            configured_id="$(node_meta '.ssh_identity_file' "")"
            user_id="$HOME/.ssh/$USER"

            if [ -n "$configured_id" ]; then
              eval configured_id="$configured_id"
            fi

            if [ -n "$configured_id" ] && [ -f "$configured_id" ]; then
              key_path="$configured_id"
            elif [ -f "$user_id" ]; then
              key_path="$user_id"
            fi

            if [ -n "$key_path" ]; then
              fp="$(${pkgs.openssh}/bin/ssh-keygen -lf "$key_path" 2>/dev/null | awk '{print $2}')"
              if [ -n "$fp" ]; then
                if ${pkgs.openssh}/bin/ssh-add -l 2>/dev/null | awk '{print $2}' | grep -q "^$fp$"; then
                  KEYS_LOADED="$KEYS_LOADED"'  '"$key_path  ($fp)"$'\n'
                else
                  KEYS_MISSING="$KEYS_MISSING"'  ssh-add "'"$key_path"'"  # '"${name}"$'\n'
                fi
              fi
            fi
          ''
        )
        enabledNodes)}

      if [ -n "$KEYS_MISSING" ] || [ -n "$KEYS_LOADED" ]; then
        echo ""
        echo "SSH Keys Status"
        if [ -n "$KEYS_MISSING" ]; then
          echo "  Missing (copy‑paste to load):"
          echo "  $KEYS_MISSING"
        fi
        if [ -n "$KEYS_LOADED" ]; then
          echo "  Loaded:"
          echo "  $KEYS_LOADED"
        fi
        echo "ssh config active: $SSH_CONFIG_FILE"
        echo ""
      fi

      echo "homelab-overkill"
      echo
      echo "nodes:"
      echo "$NODE_SUMMARIES"
      echo "dev hooks:"
      echo "  pre-commit                                      - nix run .#fmt -- --check staged *.nix"
      echo "  pre-push                                        - gitleaks secret scan"
      echo ""
      echo "commands:"
      echo "  nix run .#bootstrap                              - decrypt node metadata into .cache/nodes.json"
      echo "  deploy <install/update/test> <node>-local        - deploy via local connection"
      echo "  deploy <install/update/test> <node>-remote       - deploy via remote connection"
      echo "  secrets <cmd>                                    - manage secrets"
      echo "  ssh <node>-local                                 - ssh to node (local)"
      echo "  ssh <node>-remote                                - ssh to node (remote)"
      echo "  eval \$(nix run .#kubeconfig -- <node>-local)    - bootstrap kubeconfig (local)"
      echo "  eval \$(nix run .#kubeconfig -- <node>-remote)   - bootstrap kubeconfig (remote)"
      echo "  nix run .#fmt -- [files...]                      - format tracked/all Nix files"
      echo "  nix run .#fmt -- --check [files...]              - check formatting without edits"
      echo "  nix run .#scan                                   - gitleaks + trufflehog secret scan"
      echo "  nix run .#update                                 - update flake, fmt, scan; builds cache targets on Linux"
      echo "  HOMELAB_UPDATE_PUSH_CACHE=1 nix run .#update     - also push built outputs to Attic badwater"
      echo ""
      echo
    '';
  };
}
