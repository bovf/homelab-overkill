{
  config,
  lib,
  ...
}: let
  cfg = config.workloads.romm.igdb;
  igdbData = lib.optionalString cfg.enable (
    "  IGDB_CLIENT_ID: \"${config.sops.placeholder."media/romm/metadata/igdb/client_id"}\"\n"
    + "  IGDB_CLIENT_SECRET: \"${config.sops.placeholder."media/romm/metadata/igdb/client_secret"}\"\n"
  );
in {
  options.workloads.romm.igdb.enable = lib.mkEnableOption "RomM IGDB metadata credentials";

  config = lib.mkMerge [
    {
      sops.templates."media/romm-credentials.yaml" = {
        content = ''
          apiVersion: v1
          kind: Secret
          metadata:
            name: romm-credentials
            namespace: media
          type: Opaque
          stringData:
            DB_PASSWD: "${config.sops.placeholder."database/postgres/romm/password"}"
            ROMM_AUTH_SECRET_KEY: "${config.sops.placeholder."media/romm/auth_secret"}"
            SCREENSCRAPER_USER: "${config.sops.placeholder."media/romm/metadata/screenscraper/username"}"
            SCREENSCRAPER_PASSWORD: "${config.sops.placeholder."media/romm/metadata/screenscraper/password"}"
            RETROACHIEVEMENTS_API_KEY: "${config.sops.placeholder."media/romm/metadata/retroachievements/api_key"}"
            STEAMGRIDDB_API_KEY: "${config.sops.placeholder."media/romm/metadata/steamgriddb/api_key"}"
          ${igdbData}'';
        path = "/var/lib/rancher/k3s/server/manifests/romm-credentials.yaml";
        owner = "root";
        group = "root";
        mode = "0644";
      };
    }
    (lib.mkIf cfg.enable {
      sops.secrets."media/romm/metadata/igdb/client_id" = {};
      sops.secrets."media/romm/metadata/igdb/client_secret" = {};
    })
  ];
}
