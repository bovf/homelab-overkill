{
  description = "DobryOps Homelab - Clean and Simple";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-anywhere.url = "github:numtide/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, nixos-anywhere, disko, sops-nix, home-manager, ... }:
    let
      nodes = {
        engineer = {
          hostname = "engineer";
          role = "server";
          nodeType = "controller";
          ip = "192.168.1.6";
          domain = "pangolin.dobryops.com";
          arch = "x86_64-linux";
          enabled = true;
          specs = { cpu = 12; ram = 64; disk = 959; };
        };
        sentry-level-01 = {
          hostname = "sentry-level-01";
          role = "agent";
          nodeType = "worker";
          ip = "192.168.1.10";
          domain = "pangolin.dobryops.com";
          arch = "x86_64-linux";
          enabled = false;
          specs = { cpu = 16; ram = 32; disk = 256; };
        };
      };

      shellsLib = import ./nix/shells;
      appsLib = import ./nix/apps { inherit nixpkgs nixos-anywhere; };

      mkNodeConfig = nodeName: nodeConfig:
        nixpkgs.lib.nixosSystem {
          system = nodeConfig.arch;
          specialArgs = { inherit nodeConfig nodes nodeName; };
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            ./infrastructure
            ./nodes/${nodeName}
            ./common
            ./secrets
            ./workloads
            { networking.hostName = nodeConfig.hostname; }
          ];
        };

      enabledNodes = nixpkgs.lib.filterAttrs (_: n: n.enabled) nodes;

    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells = shellsLib { inherit pkgs enabledNodes; };
        apps = appsLib.mkApps system enabledNodes;
      }
    )
    // {
      nixosConfigurations = nixpkgs.lib.mapAttrs mkNodeConfig enabledNodes;
    };
}
