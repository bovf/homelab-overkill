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
