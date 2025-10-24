# nix/apps/deploy.nix (install case updated)
{ nixpkgs, nixos-anywhere }:
{
  mkDeployApp = system: enabledNodes:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      lib  = nixpkgs.lib;
      nodesList = lib.concatStringsSep " " (lib.attrNames enabledNodes);
      cases = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: node:
        ''  "${name}") echo "${node.ip}";;''
      ) enabledNodes);
    in
    {
      type = "app";
      program = toString (pkgs.writeShellScript "deploy" ''
        set -euo pipefail
        cmd="''${1:-help}"
        node="''${2:-}"

        list_nodes() { echo "Available nodes: ${nodesList}"; }
        ensure_arg() { if [ -z "''${node:-}" ]; then echo "Error: Missing NODE"; list_nodes; exit 1; fi; }
        ensure_tool() { command -v "''$1" >/dev/null 2>&1 || { echo "Error: missing tool: ''$1"; exit 1; }; }

        get_ip() {
          case "''${node}" in
${cases}
            *) echo "unknown";;
          esac
        }

        case "''${cmd}" in
          install)
            ensure_arg
            ensure_tool "nixos-anywhere"
            ip="$(get_ip)"
            [ "''${ip}" = "unknown" ] && { echo "Unknown node ''${node}"; list_nodes; exit 1; }
            EXTRA_DIR=".cache/extra-files/''${node}"
            extraFlag=()
            if [ -d "''${EXTRA_DIR}" ]; then
              extraFlag=(--extra-files "''${EXTRA_DIR}")
              echo "Using --extra-files ''${EXTRA_DIR}"
            else
              echo "No --extra-files for ''${node} (run: nix run .#secrets -- bootstrap ''${node})"
            fi
            ${nixos-anywhere.packages.${system}.default}/bin/nixos-anywhere \
              --flake ".#''${node}" \
              --target-host "root@''${ip}" \
              --build-on remote \
              --phases kexec,disko,install,reboot \
              "''${extraFlag[@]}" \
            ;;

          update|switch)
            ensure_arg
            ensure_tool "nixos-rebuild-ng"
            ip="$(get_ip)"
            [ "''${ip}" = "unknown" ] && { echo "Unknown node ''${node}"; list_nodes; exit 1; }
            ${pkgs.nixos-rebuild-ng}/bin/nixos-rebuild-ng switch \
              --flake ".#''${node}" \
              --target-host "root@''${ip}" \
              --build-host "root@''${ip}" \
              --sudo \
              --ask-sudo-password \
              --impure
            ;;

          test)
            ensure_arg
            ensure_tool "nixos-rebuild-ng"
            ip="$(get_ip)"
            [ "''${ip}" = "unknown" ] && { echo "Unknown node ''${node}"; list_nodes; exit 1; }
            ${pkgs.nixos-rebuild-ng}/bin/nixos-rebuild-ng test\
              --flake ".#''${node}" \
              --target-host "root@''${ip}" \
              --build-host "root@''${ip}" \
              --sudo \
              --ask-sudo-password \
              --impure
            ;;

          help|*)
            cat <<EOF
Usage: nix run .#deploy -- <command> [NODE]
Commands:
  install   Install a brand-new node via nixos-anywhere (uses .cache/extra-files/NODE if present).
  update    Update an existing node via nixos-rebuild switch.
  test      Test activation on the remote host.

Examples:
  nix run .#secrets -- bootstrap engineer
  nix run .#deploy  -- install   engineer
  nix run .#deploy  -- update    engineer
EOF
            list_nodes
            ;;
        esac
      '');
    };
}
