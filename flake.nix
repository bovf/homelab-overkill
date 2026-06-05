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

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent-src = {
      url = "github:NousResearch/hermes-agent";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, nixos-anywhere, disko, sops-nix, home-manager,
              pyproject-nix, uv2nix, pyproject-build-systems, hermes-agent-src, ... }:
    let
      nodes = {
        engineer = {
          hostname = "engineer";
          role = "server";
          nodeType = "controller";
          ip = "192.0.2.10";
          localPort = 22;

          remoteHostSecretKey = "pangolin.resources.engineer_ssh.domain";
          remotePortSecretKey = "pangolin.resources.engineer_ssh.port";

          k8sApiDomainSecretKey = "pangolin.resources.engineer_k8s_api.domain";
          k8sApiPortSecretKey   = "pangolin.resources.engineer_k8s_api.port";

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

      hermesAgentOverlay = final: prev:
        let
          workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = hermes-agent-src; };
          pyprojOverlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
          python = final.python3;
          pyprojectOverrides = pyFinal: pyPrev: {
            python-olm = pyPrev.python-olm.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
                pyFinal.setuptools
                pyFinal.cffi
                pyFinal.pycparser
              ];
              buildInputs = (old.buildInputs or []) ++ [ final.olm ];
            });
          };
          pythonSet = (final.callPackage pyproject-nix.build.packages {
            inherit python;
          }).overrideScope (
            final.lib.composeManyExtensions [
              pyproject-build-systems.overlays.wheel
              pyprojOverlay
              pyprojectOverrides
            ]
          );
          baseHermes = pythonSet.mkVirtualEnv "hermes-agent-base" (
            workspace.deps.default // {
              hermes-agent = [ "matrix" ];
            }
          );
          # mcp Python SDK is not in hermes-agent's pyproject; ship it in
          # a sibling env and append to PYTHONPATH so `hermes mcp` can talk
          # to user-registered MCP servers (e.g. koth-dm's dice/turn MCPs).
          mcpSdkEnv = python.withPackages (ps: [ ps.mcp ]);
        in {
          hermes-agent = final.runCommand "hermes-agent" {
            nativeBuildInputs = [ final.makeWrapper ];
            passthru = { inherit baseHermes mcpSdkEnv; };
          } ''
            mkdir -p $out
            for d in ${baseHermes}/*; do
              name=$(basename "$d")
              if [ "$name" = "bin" ]; then
                mkdir -p "$out/bin"
                for f in "$d"/*; do
                  bname=$(basename "$f")
                  # Wrap only executable entry points; symlink venv activate
                  # scripts (Activate.ps1, activate.csh, …) which are sourced
                  # by shells and would fail makeWrapper's assertExecutable.
                  if [ -x "$f" ] && [ ! -d "$f" ]; then
                    makeWrapper "$f" "$out/bin/$bname" \
                      --suffix PYTHONPATH : "${mcpSdkEnv}/${python.sitePackages}"
                  else
                    ln -s "$f" "$out/bin/$bname"
                  fi
                done
              else
                ln -s "$d" "$out/$name"
              fi
            done
          '';
        };

      mkNodeConfig = nodeName: nodeConfig:
        nixpkgs.lib.nixosSystem {
          system = nodeConfig.arch;
          specialArgs = { inherit nodeConfig nodes nodeName; };
          modules = [
            { nixpkgs.overlays = [ hermesAgentOverlay ]; }
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            ./infrastructure
            ./nodes/${nodeName}
            ./common
            ./secrets
            ./workloads
            { networking.hostName = nodeConfig.hostname; }
            # Force sops to recreate symlinks every activation — k3s
            # watches mtime to detect manifest changes. sops-nix builds
            # sops-install-secrets directly via callPackage so we have
            # to override sops.package, not the overlay.
            ({ pkgs, ... }: {
              sops.package = (pkgs.callPackage (sops-nix + "/pkgs/sops-install-secrets") {
                vendorHash = "sha256-PAq52bWVHqjBsPuWB86L+N0EYSUwmTUef8IFJTtRUVo=";
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
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ hermesAgentOverlay ];
        };
      in {
        devShells = shellsLib { inherit pkgs enabledNodes; };
        apps = appsLib.mkApps system enabledNodes;
        packages.hermes-agent = pkgs.hermes-agent;
      }
    )
    // {
      overlays.default = hermesAgentOverlay;
      nixosConfigurations = nixpkgs.lib.mapAttrs mkNodeConfig enabledNodes;
    };
}
