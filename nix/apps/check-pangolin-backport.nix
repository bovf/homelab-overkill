# Run: nix eval --offline --impure --file nix/apps/check-pangolin-backport.nix
let
  flake = builtins.getFlake (toString ../..);
  host = flake.nixosConfigurations.pangolin;
  checkCaughtUp = version: let
    caughtUp = host.extendModules {
      modules = [
        {
          nixpkgs.overlays = [
            (_: prev: {
              fosrl-pangolin = prev.fosrl-pangolin.overrideAttrs {
                inherit version;
                __intentionallyOverridingVersion = true;
              };
            })
          ];
        }
      ];
    };
  in
    !(builtins.tryEval caughtUp.config.system.build.toplevel.drvPath).success;
in
  assert !(host.config.systemd.services ? gerbil-basic-wg-reconcile);
  assert !host.config.services.pangolin.settings.flags.enable_acme_cert_sync;
  assert host.config.services.pangolin.package.version == "1.24.0";
  assert host.config.services.pangolin.package.npmDeps.outputHash == host.config.services.pangolin.package.npmDepsHash;
  assert host.config.services.pangolin.package.npmDeps.src == host.config.services.pangolin.package.src;
  assert (builtins.tryEval host.config.system.build.toplevel.drvPath).success;
  assert checkCaughtUp "1.24.0";
  assert checkCaughtUp "1.25.0"; "Pangolin backport and removal guard checks passed"
