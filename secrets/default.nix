{...}: {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    # Raw SSH public-key SOPS recipients, including RSA workstation keys,
    # require SOPS_AGE_SSH_PRIVATE_KEY_FILE. Existing engineer installs use
    # /root/.ssh/id_ed25519; bootstrap also stages /root/.ssh/engineer for
    # future standardization once that named key exists on the host.
    environment.SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/root/.ssh/id_ed25519";
    age.sshKeyPaths = ["/root/.ssh/id_ed25519"];
    age.generateKey = false;

    # Pangolin resource domains
    secrets."pangolin/resources/jellyfin/domain" = {};
    secrets."pangolin/resources/sonarr/domain" = {};
    secrets."pangolin/resources/radarr/domain" = {};
    secrets."pangolin/resources/bazarr/domain" = {};
    secrets."pangolin/resources/prowlarr/domain" = {};
    secrets."pangolin/resources/jellyseerr/domain" = {};
    secrets."pangolin/resources/qbittorrent/domain" = {};
    secrets."pangolin/resources/nzbget/domain" = {};
    secrets."pangolin/resources/romm/domain" = {};
    secrets."pangolin/resources/grafana/domain" = {};
    secrets."pangolin/resources/prometheus/domain" = {};
    secrets."pangolin/resources/alertmanager/domain" = {};
    secrets."pangolin/resources/minio/domain" = {};
    secrets."pangolin/resources/minio_console/domain" = {};
    secrets."pangolin/resources/pgadmin/domain" = {};
    secrets."pangolin/resources/gitlab/domain" = {};
    secrets."pangolin/resources/registry/domain" = {};
    secrets."pangolin/resources/postgres/domain" = {};
    secrets."pangolin/resources/traefik_dashboard/domain" = {};
    secrets."pangolin/resources/cam/domain" = {};
    secrets."pangolin/resources/uptime/domain" = {};
    # Uptime Kuma admin (created by the bootstrap Job on first run).
    secrets."uptime-kuma/admin_user" = {};
    secrets."uptime-kuma/admin_password" = {};
    secrets."pangolin/resources/search/domain" = {};
    secrets."pangolin/resources/speedtest/domain" = {};
    secrets."pangolin/resources/ms_kb/domain" = {};
    secrets."pangolin/resources/sparkyfitness/domain" = {};

    # SearXNG session/image-proxy signing key — `openssl rand -hex 32`.
    secrets."searxng/secret" = {};
    # Laravel APP_KEY for speedtest-tracker — must be `base64:<32 random
    # bytes base64'd>`. Generate: echo "base64:$(openssl rand -base64 32)"
    secrets."speedtest/app_key" = {};
    # GitLab project/group access token with read_repository scope for the
    # dashboard flake-lock drift widgets, including nix/pl-badwater.
    secrets."gitlab/glance_read_token" = {};

    # Pangolin TCP tunnel ports. The matching domain keys are consumed
    # at runtime by nix apps (not sops-nix on the node) so they're not
    # declared here.
    secrets."pangolin/resources/engineer_ssh/port" = {};
    secrets."pangolin/resources/engineer_k8s_api/port" = {};
    secrets."pangolin/resources/gitlab_ssh/port" = {};

    secrets."admin/base_domain" = {};
    secrets."admin/email" = {};

    # Cloudflare API token scoped to Zone:Read + Zone.DNS:Edit on the
    # dobryops.com zone. Used by cert-manager's DNS-01 solver for the
    # wildcard *.dobryops.com cert.
    secrets."cloudflare/api_token" = {};

    secrets."media/nzbget/username" = {};
    secrets."media/nzbget/password" = {};
    secrets."media/nzbget/news_server/host" = {};
    secrets."media/nzbget/news_server/username" = {};
    secrets."media/nzbget/news_server/password" = {};

    secrets."qbittorrent/password_hash" = {};
    secrets."qbittorrent/password" = {};

    secrets."protonvpn/wireguard_private_key" = {};

    secrets."monitoring/grafana-admin-password" = {};
    secrets."monitoring/grafana/renderer_token" = {};
    secrets."monitoring/alertmanager/smtp_password" = {};

    secrets."media/sonarr/api_key" = {};
    secrets."media/sonarr/admin_password" = {};
    secrets."media/radarr/api_key" = {};
    secrets."media/radarr/admin_password" = {};
    secrets."media/prowlarr/api_key" = {};
    secrets."media/prowlarr/admin_password" = {};
    secrets."media/bazarr/api_key" = {};
    secrets."media/bazarr/admin_password" = {};
    secrets."media/bazarr/admin_password_hashed" = {};
    secrets."media/bazarr/opensubtitles_username" = {};
    secrets."media/bazarr/opensubtitles_password" = {};
    secrets."media/jellyseerr/api_key" = {};
    secrets."media/jellyfin/admin_password" = {};
    secrets."media/romm/auth_secret" = {};
    secrets."media/romm/metadata/screenscraper/username" = {};
    secrets."media/romm/metadata/screenscraper/password" = {};
    secrets."media/romm/metadata/retroachievements/api_key" = {};
    secrets."media/romm/metadata/steamgriddb/api_key" = {};

    secrets."media/indexers/mma_torrents/username" = {};
    secrets."media/indexers/mma_torrents/password" = {};
    secrets."media/indexers/p2pbg/username" = {};
    secrets."media/indexers/p2pbg/password" = {};
    secrets."media/indexers/zamunda/username" = {};
    secrets."media/indexers/zamunda/password" = {};

    secrets."database/postgres/password" = {};
    secrets."database/postgres/gitlab/password" = {};
    secrets."database/postgres/romm/password" = {};
    secrets."database/pgadmin/email" = {};
    secrets."database/pgadmin/password" = {};
    secrets."database/minio/root_user" = {};
    secrets."database/minio/root_password" = {};
    secrets."database/minio/gitlab/gitlab_access_key" = {};
    secrets."database/minio/gitlab/gitlab_secret_key" = {};
    secrets."database/minio/loki/access_key" = {};
    secrets."database/minio/loki/secret_key" = {};

    secrets."gitlab/root_password" = {};
    secrets."gitlab/runner_token" = {};
    secrets."gitlab/runner_registration_token" = {};
    secrets."gitlab/nix_cache_runner_token" = {};

    secrets."argocd/admin_password" = {};
    secrets."argocd/gitlab_token" = {};
    secrets."pangolin/resources/argocd/domain" = {};

    secrets."pihole/web_password" = {};
    secrets."pangolin/resources/pihole/domain" = {};

    secrets."pangolin/resources/whoami/domain" = {};

    secrets."pangolin/resources/ezbookkeeping/domain" = {};
    secrets."database/postgres/ezbookkeeping/password" = {};
    secrets."finance/ezbookkeeping/secret_key" = {};

    secrets."database/postgres/sparkyfitness/password" = {};
    secrets."database/postgres/sparkyfitness/app_password" = {};
    secrets."sparkyfitness/api_encryption_key" = {};
    secrets."sparkyfitness/better_auth_secret" = {};

    # Pangolin VPS native service environment. This currently includes
    # SERVER_SECRET for services.pangolin.
    secrets."pangolin/env" = {};

    # Matrix (Synapse homeserver + Element Web). VoIP (Element Call / LiveKit)
    # runs on the Pangolin VPS; livekit_jwt/domain points clients at it.
    secrets."pangolin/resources/matrix/domain" = {};
    secrets."pangolin/resources/element/domain" = {};
    secrets."database/postgres/synapse/password" = {};
    secrets."matrix/synapse/signing_key" = {};
    secrets."matrix/synapse/registration_shared_secret" = {};
    secrets."matrix/synapse/macaroon_secret_key" = {};
    secrets."matrix/synapse/form_secret" = {};
    secrets."pangolin/resources/synapse_admin/domain" = {};
    secrets."pangolin/resources/livekit_jwt/domain" = {};
    secrets."matrix/livekit-api-key" = {};
    secrets."matrix/livekit-api-secret" = {};

    # Homarr — homepage / launcher. Integration API keys are entered via
    # the Homarr web UI on first boot (stored in SQLite on the appdata PVC);
    # they're declared here so a single `sops -d` reveals everything Homarr
    # ever needs in one place.
    secrets."homarr/auth_secret" = {};
    secrets."homarr/db_encryption_key" = {}; # `openssl rand -hex 32` — 64-char hex
    secrets."homarr/admin_password" = {};
    secrets."homarr/integrations/openweathermap_key" = {};
    secrets."homarr/integrations/jellyfin_key" = {};
    secrets."homarr/integrations/jellyseerr_key" = {};
    secrets."homarr/integrations/sonarr_key" = {};
    secrets."homarr/integrations/radarr_key" = {};
    secrets."homarr/integrations/bazarr_key" = {};
    secrets."homarr/integrations/prowlarr_key" = {};
    secrets."homarr/integrations/pihole_app_password" = {};
    secrets."monitoring/grafana/embed_api_token" = {};

    secrets."ssh_keys/dobrynikolov" = {};
    secrets."ssh_keys/dobrynikolov.pub" = {};
    secrets."ssh_keys/engineer" = {};
    secrets."ssh_keys/engineer.pub" = {};
  };
}
