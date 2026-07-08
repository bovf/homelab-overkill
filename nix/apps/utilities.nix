{nixpkgs, ...}: {
  mkStatusApp = system: enabledNodes: let
    lib = nixpkgs.lib;
    pkgs = import nixpkgs {inherit system;};
  in {
    type = "app";
    program = toString (pkgs.writeShellScript "status" ''
      set -euo pipefail

      echo "homelab status"
      echo ""

      NODES_JSON=".cache/nodes.json"
      if [ ! -f "$NODES_JSON" ]; then
        echo "Error: $NODES_JSON not found — node addresses live in SOPS, not the repo." >&2
        echo "  Run: nix run .#bootstrap" >&2
        exit 1
      fi

      node_meta() {
        local filter="$1"
        local default="$2"
        local value
        value="$(${pkgs.jq}/bin/jq -r "$filter // empty" "$NODES_JSON" 2>/dev/null || true)"
        if [ -n "$value" ]; then
          printf "%s" "$value"
        else
          printf "%s" "$default"
        fi
      }

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: node: let
          localEnabled = node.localTarget or true;
          remoteEnabled = node.remoteTarget or true;
          localPort = toString (node.localPort or 22);
          remotePortDefault = toString (node.remotePort or (node.localPort or 22));
        in ''
          # ${name}
          {
            ${lib.optionalString localEnabled ''
            ip="$(node_meta '.["${name}"].ip' "")"
            port="${localPort}"

            if [ -n "$ip" ]; then
              echo -n "${name} (local: $ip:$port): "
              if ping -c 1 -W 3 "$ip" >/dev/null 2>&1; then
                echo "online"
              else
                echo "offline"
              fi
            fi
          ''}

            ${lib.optionalString remoteEnabled ''
            remote_host="$(node_meta '.["${name}"].ip' "")"
            remote_port="${remotePortDefault}"

            if [ -n "$remote_host" ]; then
              echo -n "${name} (remote: $remote_host:$remote_port): "
              if ping -c 1 -W 3 "$remote_host" >/dev/null 2>&1; then
                echo "online"
              else
                echo "offline"
              fi
            fi
          ''}
          }
        '')
        enabledNodes)}
    '');
  };
}
