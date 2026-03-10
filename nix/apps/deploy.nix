{ nixpkgs, nixos-anywhere }:
{
  mkDeployApp = system: enabledNodes:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      lib  = nixpkgs.lib;
    in
    {
      type = "app";
      program = toString (pkgs.writeShellScript "deploy" ''
        set -euo pipefail
        cmd="''${1:-help}"
        node_target="''${2:-}"

        list_nodes() { 
          echo "Available node targets:"
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: _:
            ''echo "  ${name}-local"''
            + "\n" +
            ''echo "  ${name}-remote"''
          ) enabledNodes)}
        }

        ensure_arg() { 
          if [ -z "''${node_target:-}" ]; then 
            echo "Error: Missing NODE_TARGET (e.g., engineer-local or engineer-remote)"
            list_nodes
            exit 1
          fi 
        }

        ensure_tool() { 
          command -v "''$1" >/dev/null 2>&1 || { 
            echo "Error: missing tool: ''$1"
            exit 1
          }
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
            echo "Error: Invalid target format '$target'. Use <node>-local or <node>-remote"
            list_nodes
            exit 1
          fi
        }

        node=""
        mode=""

        case "''${cmd}" in
          install)
            ensure_arg
            ensure_tool "nixos-anywhere"
            parse_node_target "''${node_target}"

            EXTRA_DIR=".cache/extra-files/''${node}"
            extraFlag=()
            if [ -d "''${EXTRA_DIR}" ]; then
              extraFlag=(--extra-files "''${EXTRA_DIR}")
              echo "Using --extra-files ''${EXTRA_DIR}"
            else
              echo "No --extra-files for ''${node} (run: nix run .#secrets -- bootstrap ''${node})"
            fi

            echo "Installing ''${node} via ''${mode}..."

            ${nixos-anywhere.packages.${system}.default}/bin/nixos-anywhere \
              --flake ".#''${node}" \
              --target-host "''${node_target}" \
              --build-on remote \
              --phases kexec,disko,install,reboot \
              "''${extraFlag[@]}"
            ;;

          update|switch)
            ensure_arg
            parse_node_target "''${node_target}"

            echo "Updating ''${node} via ''${mode}..."

            ${lib.getExe pkgs.nixos-rebuild-ng} switch \
              --flake ".#''${node}" \
              --target-host "''${node_target}" \
              --build-host "''${node_target}" \
              --sudo \
              --ask-sudo-password \
              --impure
            ;;

          test)
            ensure_arg
            parse_node_target "''${node_target}"

            echo "Testing ''${node} via ''${mode}..."

            ${lib.getExe pkgs.nixos-rebuild-ng} test \
              --flake ".#''${node}" \
              --target-host "''${node_target}" \
              --build-host "''${node_target}" \
              --sudo \
              --ask-sudo-password \
              --impure
            ;;

          status)
            ensure_arg
            parse_node_target "''${node_target}"

            echo -n "Status for ''${node} (''${mode}): "
            if ssh "''${node_target}" "whoami" >/dev/null 2>&1; then
              echo "online"
            else
              echo "offline"
            fi
            ;;

          help|*)
            cat <<EOF
Usage: nix run .#deploy -- <command> <NODE_TARGET>

Commands:
  install   Install a brand-new node via nixos-anywhere (uses .cache/extra-files/NODE if present).
  update    Update an existing node via nixos-rebuild-ng switch.
  test      Test activation on the remote host.
  status    Check if node is reachable.

NODE_TARGET format:
  <node>-local   Use local connection (node.ip:localPort from flake config)
  <node>-remote  Use remote connection (node.remoteHost:remotePort from flake config)

SSH config:
  SSH config is generated in nix develop shell with entries for both local and remote.
  Target hostname is resolved via SSH config (SSH_CONFIG_FILE environment variable).

Examples:
  nix develop
  ssh engineer-local               # test local connection
  ssh engineer-remote              # test remote connection
  nix run .#secrets -- bootstrap engineer
  nix run .#deploy -- install engineer-local
  nix run .#deploy -- install engineer-remote
  nix run .#deploy -- update engineer-local
EOF
            list_nodes
            ;;
        esac
      '');
    };
}
