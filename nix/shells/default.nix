{ pkgs, enabledNodes, ... }:

{
  default = pkgs.mkShell {
    packages = with pkgs; [
      kubectl
      kubernetes-helm
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
    ] ++ (pkgs.lib.optionals pkgs.stdenv.isLinux [ iproute2 ]);

    shellHook = ''
      echo "homelab-overkill"
      echo ""
      echo "nodes:"
      ${pkgs.lib.concatStringsSep "\n" (
        pkgs.lib.mapAttrsToList (name: node:
          "echo '  ${name} - ${node.role}/${node.nodeType} - ${node.ip}'"
        ) enabledNodes
      )}
      echo ""
      echo "commands:"
      echo "  deploy <install/update> <node>            - deploy configuration to node"
      echo "  secrets <cmd>                             - manage secrets"
      echo "  ssh <node>                                - ssh to node"
      echo "  status                                    - cluster status"
      echo ""
    '';
  };
}
