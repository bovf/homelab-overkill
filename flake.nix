{
  description = "DobryOps Homelab - Clean and Simple";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-anywhere.url = "github:numtide/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nixos-anywhere,
    nixos-generators,
    disko,
    sops-nix,
    home-manager,
    pyproject-nix,
    uv2nix,
    pyproject-build-systems,
    hermes-agent-src,
    ...
  }: let
    # Node addresses, ssh user, and identity file are NOT stored here — the
    # repo is public. They live encrypted in secrets/secrets.yaml under
    # `nodes:` and are materialized locally into .cache/nodes.json by
    # `nix run .#bootstrap`. Dev shells and apps resolve them at runtime.
    nodes = {
      engineer = {
        hostname = "engineer";
        role = "server";
        nodeType = "controller";
        localPort = 22;

        remoteHostSecretKey = "pangolin.resources.engineer_ssh.domain";
        remotePortSecretKey = "pangolin.resources.engineer_ssh.port";

        k8sApiDomainSecretKey = "pangolin.resources.engineer_k8s_api.domain";
        k8sApiPortSecretKey = "pangolin.resources.engineer_k8s_api.port";

        domain = "pangolin.dobryops.com";
        arch = "x86_64-linux";
        enabled = true;
        localTarget = true;
        remoteTarget = true;
        deploy = {
          useSudo = true;
          requireConfirmation = false;
        };
        installIsoModules = [
          ./nodes/engineer/hardware.nix
          ./nodes/engineer/disko.nix
          ./common/users.nix
        ];
        specs = {
          cpu = 12;
          ram = 64;
          disk = 959;
        };
      };

      pangolin = {
        hostname = "pangolin";
        role = "edge";
        nodeType = "vps";
        localTarget = false;
        remoteTarget = true;
        remotePort = 22;

        sshAliases = ["pangolin"];

        domain = "pangolin.dobryops.com";
        arch = "x86_64-linux";
        enabled = true;
        deploy = {
          useSudo = true;
          requireConfirmation = false;
        };
        installIsoModules = [
          ./nodes/pangolin/configuration.nix
          ./nodes/pangolin/virtualization.nix
          ./nodes/pangolin/firewall.nix
        ];
        specs = {
          cpu = 2;
          ram = 4;
          disk = 80;
        };
      };

      # sentry-level-01 = {
      #   hostname = "sentry-level-01";
      #   role = "agent";
      #   nodeType = "worker";
      #   localPort = 22;
      #
      #   remoteHostSecretKey = "sentry-level-01.remoteHost";
      #   remotePortSecretKey = "sentry-level-01.remotePort";
      #
      #   domain = "pangolin.dobryops.com";
      #   arch = "x86_64-linux";
      #   enabled = false;
      #   specs = { cpu = 16; ram = 32; disk = 256; };
      # };
    };

    shellsLib = import ./nix/shells;
    appsLib = import ./nix/apps {inherit nixpkgs nixos-anywhere;};
    imagesLib = import ./nix/images {inherit nixpkgs nixos-generators disko;};

    hermesAgentOverlay = final: prev: let
      workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = hermes-agent-src;};
      pyprojOverlay = workspace.mkPyprojectOverlay {sourcePreference = "wheel";};
      # Hermes currently requires Python <3.14; nixpkgs' python3 may move ahead.
      python = final.python313;
      pyprojectOverrides = pyFinal: pyPrev: {
        python-olm = pyPrev.python-olm.overrideAttrs (old: {
          nativeBuildInputs =
            (old.nativeBuildInputs or [])
            ++ [
              pyFinal.setuptools
              pyFinal.cffi
              pyFinal.pycparser
            ];
          buildInputs = (old.buildInputs or []) ++ [final.olm];
        });
      };
      pythonSet =
        (final.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope (
          final.lib.composeManyExtensions [
            pyproject-build-systems.overlays.wheel
            pyprojOverlay
            pyprojectOverrides
          ]
        );
      baseHermes = pythonSet.mkVirtualEnv "hermes-agent-base" (
        workspace.deps.default
        // {
          hermes-agent = ["matrix"];
        }
      );
      # mcp Python SDK is not in hermes-agent's pyproject; ship it in
      # a sibling env and append to PYTHONPATH so `hermes mcp` can talk
      # to user-registered MCP servers (e.g. koth-dm's dice/turn MCPs).
      mcpSdkEnv = python.withPackages (ps: [ps.mcp]);
    in {
      hermes-agent =
        final.runCommand "hermes-agent" {
          nativeBuildInputs = [final.makeWrapper];
          passthru = {inherit baseHermes mcpSdkEnv;};
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

    mkNodeConfig = nodeName: nodeConfig: let
      sharedBaseModules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./nodes/${nodeName}
        {networking.hostName = nodeConfig.hostname;}
      ];

      engineerOnlyModules = nixpkgs.lib.optionals (nodeName == "engineer") [
        {nixpkgs.overlays = [hermesAgentOverlay];}
        home-manager.nixosModules.home-manager
        ./infrastructure
        ./common
        ./secrets
        ./workloads
        # Force sops to recreate symlinks every activation — k3s
        # watches mtime to detect manifest changes. sops-nix builds
        # sops-install-secrets directly via callPackage so we have
        # to override sops.package, not the overlay.
        ({pkgs, ...}: {
          sops.package =
            (pkgs.callPackage (sops-nix + "/pkgs/sops-install-secrets") {
              vendorHash = "sha256-ANh5X1ZWtkHaQ0AVBoHTHETUSyb0DVhRvfqdKwYLYbs=";
            }).overrideAttrs (old: {
              patches = (old.patches or []) ++ [./nix/patches/sops-always-recreate-symlink.patch];
            });
        })
      ];
    in
      nixpkgs.lib.nixosSystem {
        system = nodeConfig.arch;
        specialArgs = {inherit nodeConfig nodes nodeName;};
        modules = sharedBaseModules ++ engineerOnlyModules;
      };

    enabledNodes = nixpkgs.lib.filterAttrs (_: n: n.enabled) nodes;
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [hermesAgentOverlay];
          config.permittedInsecurePackages = ["olm-3.2.16"];
        };
      in {
        devShells = shellsLib {inherit pkgs enabledNodes;};
        apps = appsLib.mkApps system enabledNodes;
        packages =
          {hermes-agent = pkgs.hermes-agent;}
          // imagesLib.mkImages system enabledNodes;
      }
    )
    // {
      overlays.default = hermesAgentOverlay;
      nixosConfigurations = nixpkgs.lib.mapAttrs mkNodeConfig enabledNodes;
    };
}
