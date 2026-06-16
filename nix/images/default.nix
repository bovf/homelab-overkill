{
  nixpkgs,
  nixos-generators,
  disko,
  ...
}: let
  lib = nixpkgs.lib;

  mkInstallIso = _system: nodeName: nodeConfig:
    nixos-generators.nixosGenerate {
      system = nodeConfig.arch;
      format = "install-iso";
      modules =
        [
          disko.nixosModules.disko
          ({pkgs, ...}: {
            networking.hostName = "${nodeConfig.hostname}-install";

            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "prohibit-password";
                PasswordAuthentication = false;
                PubkeyAuthentication = true;
              };
            };

            environment.systemPackages = with pkgs; [
              curl
              git
              htop
              jq
              vim
              wget
            ];
          })
        ]
        ++ (nodeConfig.installIsoModules or []);
    };
in {
  mkImages = system: enabledNodes:
    lib.mapAttrs'
    (nodeName: nodeConfig: {
      name = "${nodeName}-install-iso";
      value = mkInstallIso system nodeName nodeConfig;
    })
    (lib.filterAttrs (_: nodeConfig: (nodeConfig.installIsoModules or []) != []) enabledNodes);
}
