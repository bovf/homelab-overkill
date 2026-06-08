{nixpkgs, ...}: {
  mkUpdateApp = system: enabledNodes: let
    pkgs = import nixpkgs {inherit system;};
    lib = pkgs.lib;
    nixosTargets =
      lib.mapAttrsToList (
        name: _node: ''.#nixosConfigurations.${name}.config.system.build.toplevel''
      )
      enabledNodes;
    packageTargets = [
      ''.#packages.${system}.hermes-agent''
    ];
    buildTargets = nixosTargets ++ packageTargets;
    targetLines = lib.concatMapStringsSep "\n" (target: ''"${target}" \'') buildTargets;
    defaultBuild =
      if system == "x86_64-linux"
      then "1"
      else "0";
    script = pkgs.writeShellApplication {
      name = "update";
      runtimeInputs = with pkgs; [attic-client coreutils git gnugrep nix];
      text = ''
                set -euo pipefail

                build_mode="''${HOMELAB_UPDATE_BUILD:-${defaultBuild}}"
                push_cache="''${HOMELAB_UPDATE_PUSH_CACHE:-0}"
                cache_name="''${HOMELAB_UPDATE_CACHE_NAME:-badwater}"
                attic_server="''${ATTIC_SERVER:-https://cache.dobryops.com}"

                echo "==> updating flake inputs"
                nix flake update

                echo "==> formatting"
                nix run .#fmt

                echo "==> scanning"
                nix run .#scan

                if [ "$build_mode" != "1" ]; then
                  echo "==> skipping cache builds on ${system}; set HOMELAB_UPDATE_BUILD=1 to force"
                  exit 0
                fi

                if [ "$push_cache" = "1" ]; then
                  if [ -z "''${ATTIC_TOKEN:-}" ]; then
                    echo "ATTIC_TOKEN is required when HOMELAB_UPDATE_PUSH_CACHE=1" >&2
                    exit 1
                  fi
                  echo "==> logging into Attic at $attic_server"
                  attic login local "$attic_server" "$ATTIC_TOKEN" --set-default
                fi

                build_and_maybe_push() {
                  local target="$1"
                  echo "==> building $target"
                  mapfile -t outputs < <(nix build "$target" --print-out-paths --no-link --accept-flake-config)
                  if [ "''${#outputs[@]}" -eq 0 ]; then
                    echo "==> no outputs for $target"
                    return 0
                  fi

                  if [ "$push_cache" = "1" ]; then
                    echo "==> pushing $target outputs to Attic cache $cache_name"
                    attic push "$cache_name" "''${outputs[@]}"
                  else
                    echo "==> cache push disabled; outputs:"
                    printf '  %s\n' "''${outputs[@]}"
                  fi
                }

                targets=(
        ${targetLines}
                )

                for target in "''${targets[@]}"; do
                  build_and_maybe_push "$target"
                done
      '';
    };
  in {
    type = "app";
    program = "${script}/bin/update";
  };
}
