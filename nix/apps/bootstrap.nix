{nixpkgs}: {
  mkBootstrapApp = system: let
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    type = "app";
    program = toString (pkgs.writeShellScript "bootstrap" ''
      set -euo pipefail

      export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

      if [ ! -f "secrets/secrets.yaml" ]; then
        echo "Error: secrets/secrets.yaml not found (run from the repo root)" >&2
        exit 1
      fi

      if [ ! -s "$SOPS_AGE_KEY_FILE" ]; then
        printf "No age key detected. Would you like to configure one now (y/n)? "
        if ! read -r answer; then
          answer=n
        fi

        case "$answer" in
          y|Y|yes|YES|Yes)
            host="$(${pkgs.hostname}/bin/hostname -s)"
            ssh_key="$HOME/.ssh/$host"
            if [ ! -f "$ssh_key" ]; then
              echo "Error: SSH private key not found at $ssh_key." >&2
              echo "  Add the host key there before continuing bootstrap." >&2
              exit 1
            fi

            key_dir="$(${pkgs.coreutils}/bin/dirname "$SOPS_AGE_KEY_FILE")"
            ${pkgs.coreutils}/bin/mkdir -p "$key_dir"
            ${pkgs.coreutils}/bin/chmod 700 "$key_dir"
            temp_key="$(${pkgs.coreutils}/bin/mktemp "$key_dir/.keys.txt.XXXXXX")"
            trap '${pkgs.coreutils}/bin/rm -f "$temp_key"' EXIT

            if ! ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$ssh_key" > "$temp_key"; then
              echo "Error: failed to derive an age identity from $ssh_key." >&2
              exit 1
            fi
            if ! ${pkgs.age}/bin/age-keygen -y "$temp_key" >/dev/null; then
              echo "Error: $ssh_key did not produce a valid age identity." >&2
              exit 1
            fi

            ${pkgs.coreutils}/bin/chmod 600 "$temp_key"
            ${pkgs.coreutils}/bin/mv "$temp_key" "$SOPS_AGE_KEY_FILE"
            trap - EXIT
            echo "Configured age identity from $ssh_key at $SOPS_AGE_KEY_FILE."
            ;;
          *)
            echo "Error: an age identity is required to continue bootstrap." >&2
            echo "  Configure $SOPS_AGE_KEY_FILE and rerun nix run .#bootstrap." >&2
            exit 1
            ;;
        esac
      fi

      if ! nodes_yaml="$(${pkgs.sops}/bin/sops --decrypt --extract '["nodes"]' secrets/secrets.yaml 2>/dev/null)"; then
        echo "Error: could not decrypt the nodes block from secrets/secrets.yaml." >&2
        echo "  Expected an age key at: $SOPS_AGE_KEY_FILE" >&2
        exit 1
      fi

      mkdir -p .cache
      umask 077
      printf "%s\n" "$nodes_yaml" | ${pkgs.yq-go}/bin/yq -o=json '.' > .cache/nodes.json

      echo "Wrote .cache/nodes.json (nodes: $(${pkgs.jq}/bin/jq -r '[keys[] | select(. != "ssh_user" and . != "ssh_identity_file")] | join(", ")' .cache/nodes.json))"
      echo "Dev shells and nix apps now resolve node addresses from it."
    '');
  };
}
