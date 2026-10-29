# Run: nix eval --offline --impure --file nix/apps/check-pangolin.nix
let
  flake = builtins.getFlake (toString ../..);
  inherit (flake.inputs.nixpkgs) lib;
  host = flake.nixosConfigurations.pangolin;
  inherit (host.config) services systemd;
  package = services.pangolin.package;
in
  assert package.drvPath == host.pkgs.fosrl-pangolin.drvPath;
  assert lib.versionAtLeast package.version "1.24.0";
  assert !(systemd.services ? gerbil-basic-wg-reconcile);
  assert !services.pangolin.settings.flags.enable_acme_cert_sync;
  assert services.traefik.staticConfigOptions.experimental.localPlugins.badger.moduleName == "github.com/fosrl/badger";
  assert !systemd.services.traefik.stopIfChanged;
  assert lib.hasInfix "cp -r --no-preserve=mode" systemd.services.pangolin.preStart;
  assert lib.hasInfix ".next/.nix_skip_setup" systemd.services.pangolin.preStart;
  assert (builtins.tryEval host.config.system.build.toplevel.drvPath).success; "Pangolin upstream package and compatibility checks passed"
