{ config, lib, ... }:
with lib;
let
  cfg = config.services.pangolin-kwg;
in {
  config = mkMerge [
    (mkIf cfg.enable {
      sops.secrets = {
        ${cfg.site.privateKeySopsPath} = {};
        # Consumed via sops.placeholder by the blueprint renderer; the
        # placeholder lookup requires the secret to be declared.
        ${cfg.site.siteIdSopsPath}     = {};
      };
    })
    (mkIf (cfg.enable && cfg.blueprintSync.enable) {
      sops.secrets.${cfg.blueprintSync.apiKeySopsPath} = {};
    })
  ];
}
