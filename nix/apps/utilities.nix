{nixpkgs, ...}: {
  mkStatusApp = system: enabledNodes: let
    lib = nixpkgs.lib;
  in {
    type = "app";
    program = toString ((import nixpkgs {inherit system;}).writeShellScript "status" ''
      set -euo pipefail

      echo "homelab status"
      echo ""
      echo "Using static node metadata only; this command does not decrypt SOPS secrets."
      echo ""

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: node: let
          localEnabled = node.localTarget or true;
          remoteEnabled = node.remoteTarget or true;
          localHost = node.ip or "";
          localPort = toString (node.localPort or 22);
          remoteHostDefault = node.remoteHost or localHost;
          remotePortDefault = toString (node.remotePort or (node.localPort or 22));
        in ''
          # ${name}
          {
            ${lib.optionalString localEnabled ''
            ip="${localHost}"
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
            remote_host="${remoteHostDefault}"
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
