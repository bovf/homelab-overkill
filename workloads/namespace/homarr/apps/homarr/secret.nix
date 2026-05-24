{ config, ... }:

# Homarr's runtime env vars. Note: Homarr v1 stores INTEGRATION credentials
# (Jellyfin/Sonarr/Radarr/etc. API keys) in its own SQLite database, entered
# via the web UI on first run. They aren't sourced from this Secret at run
# time — but the canonical values live in sops at the paths listed in the
# `STRINGDATA INTEGRATIONS REFERENCE` block below, so you have one place to
# `sops -d secrets/secrets.yaml` and copy from when configuring Homarr's
# Settings → Integrations on first boot.
{
  sops.templates."homarr/env.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: homarr-env
        namespace: homarr
      type: Opaque
      stringData:
        # --- Runtime env vars (consumed by the Homarr pod) ---
        AUTH_SECRET: "${config.sops.placeholder."homarr/auth_secret"}"
        # 64-char hex; rotates Homarr's SQLite-stored integration creds. NEVER
        # change this after first boot — existing encrypted rows become
        # unreadable. `openssl rand -hex 32`.
        SECRET_ENCRYPTION_KEY: "${config.sops.placeholder."homarr/db_encryption_key"}"
        AUTH_PROVIDERS: "credentials"
        BASE_URL: "https://${config.sops.placeholder."pangolin/resources/home/domain"}"

        # --- INTEGRATIONS REFERENCE (not consumed by the pod — sourced
        #     here so all Homarr-related secrets sit in one Secret on
        #     disk for ops convenience; you enter these into the Homarr
        #     UI on first boot, where they get stored in the SQLite DB
        #     on the appdata PVC) ---
        OPENWEATHERMAP_KEY: "${config.sops.placeholder."homarr/integrations/openweathermap_key"}"
        JELLYFIN_KEY: "${config.sops.placeholder."homarr/integrations/jellyfin_key"}"
        JELLYSEERR_KEY: "${config.sops.placeholder."homarr/integrations/jellyseerr_key"}"
        SONARR_KEY: "${config.sops.placeholder."homarr/integrations/sonarr_key"}"
        RADARR_KEY: "${config.sops.placeholder."homarr/integrations/radarr_key"}"
        BAZARR_KEY: "${config.sops.placeholder."homarr/integrations/bazarr_key"}"
        PROWLARR_KEY: "${config.sops.placeholder."homarr/integrations/prowlarr_key"}"
        PIHOLE_APP_PASSWORD: "${config.sops.placeholder."homarr/integrations/pihole_app_password"}"
        QBITTORRENT_PASSWORD: "${config.sops.placeholder."qbittorrent/password"}"
        NZBGET_USERNAME: "${config.sops.placeholder."media/nzbget/username"}"
        NZBGET_PASSWORD: "${config.sops.placeholder."media/nzbget/password"}"
        GRAFANA_EMBED_API_TOKEN: "${config.sops.placeholder."monitoring/grafana/embed_api_token"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/homarr-env.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
