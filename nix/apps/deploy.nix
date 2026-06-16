{
  nixpkgs,
  nixos-anywhere,
}: {
  mkDeployApp = system: enabledNodes: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = nixpkgs.lib;

    targetEntries = lib.concatMapAttrs (nodeName: nodeConfig:
      lib.optionalAttrs (nodeConfig.localTarget or true) {
        "${nodeName}-local" = {
          node = nodeName;
          mode = "local";
          useSudo = nodeConfig.deploy.useSudo or true;
          requireConfirmation = nodeConfig.deploy.requireConfirmation or false;
        };
      }
      // lib.optionalAttrs (nodeConfig.remoteTarget or true) {
        "${nodeName}-remote" = {
          node = nodeName;
          mode = "remote";
          useSudo = nodeConfig.deploy.useSudo or true;
          requireConfirmation = nodeConfig.deploy.requireConfirmation or false;
        };
      })
    enabledNodes;

    listNodeLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (targetName: _: ''echo "  ${targetName}"'') targetEntries);

    parseCases = lib.concatStringsSep "\n" (lib.mapAttrsToList (targetName: target: ''
        ${targetName})
          node="${target.node}"
          mode="${target.mode}"
          use_sudo="${
          if target.useSudo
          then "1"
          else "0"
        }"
          require_confirmation="${
          if target.requireConfirmation
          then "1"
          else "0"
        }"
          ;;
      '')
      targetEntries);
  in {
    type = "app";
    program = toString (pkgs.writeShellScript "deploy" ''
      set -euo pipefail
      cmd="''${1:-help}"
      node_target="''${2:-}"

      list_nodes() {
        echo "Available node targets:"
        ${listNodeLines}
      }

      ensure_arg() {
        if [ -z "''${node_target:-}" ]; then
          echo "Error: Missing NODE_TARGET (e.g., engineer-local, engineer-remote, pangolin-remote)"
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

      node=""
      mode=""
      use_sudo="1"
      require_confirmation="0"

      parse_node_target() {
        local target="$1"
        case "$target" in
      ${parseCases}
          *)
            echo "Error: Invalid or unsupported target '$target'."
            list_nodes
            exit 1
            ;;
        esac
      }

      confirm_if_needed() {
        local operation="$1"
        local confirmation=""
        if [ "$require_confirmation" = "1" ]; then
          # Fake sudo-style prompt for root SSH targets. This intentionally
          # mimics nixos-rebuild-ng's engineer sudo prompt as a manual safety
          # gate, but the value is not used because the target user is root.
          printf "[sudo] password for %s: " "$node_target" >&2
          read -r -s confirmation
          printf "\n" >&2
          if [ -z "$confirmation" ]; then
            echo "Empty confirmation for $node_target ($operation); aborting." >&2
            exit 1
          fi
        fi
      }

      make_rebuild_args() {
        rebuildArgs=(
          --flake ".#''${node}"
          --target-host "''${node_target}"
          --build-host "''${node_target}"
          --impure
        )
        if [ "$use_sudo" = "1" ]; then
          rebuildArgs+=(--sudo --ask-sudo-password)
        fi
      }

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
          confirm_if_needed "switch"

          echo "Updating ''${node} via ''${mode}..."

          make_rebuild_args
          ${lib.getExe pkgs.nixos-rebuild-ng} switch "''${rebuildArgs[@]}"
          ;;

        test)
          ensure_arg
          parse_node_target "''${node_target}"
          confirm_if_needed "test"

          echo "Testing ''${node} via ''${mode}..."

          make_rebuild_args
          ${lib.getExe pkgs.nixos-rebuild-ng} test "''${rebuildArgs[@]}"
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
        switch    Alias for update.
        test      Test activation on the remote host.
        status    Check if node is reachable.

      NODE_TARGET examples:
        engineer-local    Engineer over LAN
        engineer-remote   Engineer through Pangolin SSH resource
        pangolin-remote   Pangolin VPS over public SSH

      SSH config:
        SSH config is generated in nix develop shell.
        Target hostname is resolved via SSH config (SSH_CONFIG_FILE environment variable).

      Examples:
        nix develop
        ssh engineer-local
        ssh engineer-remote
        ssh pangolin-remote
        nix run .#deploy -- install engineer-local
        nix run .#deploy -- update engineer-local
        nix run .#deploy -- update pangolin-remote
      EOF
          list_nodes
          ;;
      esac
    '');
  };
}
