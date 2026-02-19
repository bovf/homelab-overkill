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
      # Node schema with secret placeholders and optional identity/user
      nodes = {
        engineer = {
          hostname = "engineer";
          role = "server";
          nodeType = "controller";
          ip = "192.0.2.10";
          localPort = 22;

          # Secret paths under .ssh.* in secrets/secrets.yaml
          remoteHostSecretKey = "engineer.remoteHost";
          remotePortSecretKey = "engineer.remotePort";

          # Optional per-node SSH identity (any path: ~/, ./, etc.)
          identityFile = "~/.ssh/id_homelab";
          sshUser = "root";

          domain = "pangolin.dobryops.com";
          arch = "x86_64-linux";
          enabled = true;
          specs = { cpu = 12; ram = 64; disk = 959; };
        };

        # sentry-level-01 = {
        #   hostname = "sentry-level-01";
        #   role = "agent";
        #   nodeType = "worker";
        #   ip = "192.168.1.10";
        #   localPort = 22;
        #
        #   remoteHostSecretKey = "sentry-level-01.remoteHost";
        #   remotePortSecretKey = "sentry-level-01.remotePort";
        #
        #   identityFile = "~/.ssh/id_ed25519_sentry";
        #   sshUser = "root";
        #
        #   domain = "pangolin.dobryops.com";
        #   arch = "x86_64-linux";
        #   enabled = false;
        #   specs = { cpu = 16; ram = 32; disk = 256; };
        # };
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
            # Patch sops-install-secrets to always recreate symlinks so that
            # k3s detects mtime changes on every nixos-rebuild switch.
            # sops-nix builds sops-install-secrets via pkgs.callPackage directly
            # from its own source tree, bypassing nixpkgs overlays. We must
            # override sops.package explicitly with a patched derivation.
            ({ pkgs, ... }: {
              sops.package = (pkgs.callPackage (sops-nix + "/pkgs/sops-install-secrets") {
                vendorHash = "sha256-b+yUkMeIKiozlrANOwaMY2QDWo0cZYpD9SXZuSgYUQs=";
              }).overrideAttrs (old: {
                patches = (old.patches or []) ++ [ ./nix/patches/sops-always-recreate-symlink.patch ];
              });
            })
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
