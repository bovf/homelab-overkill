# nix/apps/utilities.nix
{ nixpkgs, ... }:

{
  mkStatusApp = system: enabledNodes: {
    type = "app";
    program = toString ((import nixpkgs { inherit system; }).writeShellScript "status" ''
      echo "homelab status"
      echo ""
${nixpkgs.lib.concatStringsSep "\n" (nixpkgs.lib.mapAttrsToList (name: node: ''
      echo -n "${name} (${node.ip}): "
      if ping -c 1 -W 3 ${node.ip} >/dev/null 2>&1; then
        echo "online"
      else
        echo "offline"
      fi
'') enabledNodes)}
    '');
  };
}
