{ ... }:

{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];
    age.generateKey = true;

    # Pangolin resource domains
    secrets."pangolin/resources/jellyfin/domain"         = {};
    secrets."pangolin/resources/sonarr/domain"           = {};
    secrets."pangolin/resources/radarr/domain"           = {};
    secrets."pangolin/resources/bazarr/domain"           = {};
    secrets."pangolin/resources/prowlarr/domain"         = {};
    secrets."pangolin/resources/jellyseerr/domain"       = {};
    secrets."pangolin/resources/qbittorrent/domain"      = {};
    secrets."pangolin/resources/nzbget/domain"           = {};
    secrets."pangolin/resources/grafana/domain"          = {};
    secrets."pangolin/resources/prometheus/domain"       = {};
    secrets."pangolin/resources/alertmanager/domain"     = {};
    secrets."pangolin/resources/minio/domain"            = {};
    secrets."pangolin/resources/minio_console/domain"    = {};
    secrets."pangolin/resources/pgadmin/domain"          = {};
    secrets."pangolin/resources/gitlab/domain"           = {};
    secrets."pangolin/resources/registry/domain"         = {};
    secrets."pangolin/resources/postgres/domain"         = {};
    secrets."pangolin/resources/mumble/domain"           = {};
    secrets."pangolin/resources/traefik_dashboard/domain" = {};

    # Pangolin TCP tunnel ports. The matching domain keys are consumed
    # at runtime by nix apps (not sops-nix on the node) so they're not
    # declared here.
    secrets."pangolin/resources/engineer_ssh/port"     = {};
    secrets."pangolin/resources/engineer_k8s_api/port" = {};
    secrets."pangolin/resources/gitlab_ssh/port"       = {};

    secrets."admin/base_domain" = {};
    secrets."admin/email"       = {};

    # Cloudflare API token scoped to Zone:Read + Zone.DNS:Edit on the
    # dobryops.com zone. Used by cert-manager's DNS-01 solver for the
    # wildcard *.dobryops.com cert.
    secrets."cloudflare/api_token" = {};

    secrets."media/nzbget/username" = {};
    secrets."media/nzbget/password" = {};
    secrets."media/nzbget/news_server/host"     = {};
    secrets."media/nzbget/news_server/username" = {};
    secrets."media/nzbget/news_server/password" = {};

    secrets."qbittorrent/password_hash" = {};
    secrets."qbittorrent/password" = {};

    secrets."nordvpn/wireguard_private_key" = {};

    secrets."monitoring/grafana-admin-password" = {};
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

    secrets."media/indexers/mma_torrents/username" = {};
    secrets."media/indexers/mma_torrents/password" = {};
    secrets."media/indexers/p2pbg/username" = {};
    secrets."media/indexers/p2pbg/password" = {};
    secrets."media/indexers/zamunda/username" = {};
    secrets."media/indexers/zamunda/password" = {};

    secrets."database/postgres/password" = {};
    secrets."database/postgres/gitlab/password" = {};
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

    secrets."argocd/admin_password" = {};
    secrets."argocd/gitlab_token" = {};
    secrets."pangolin/resources/argocd/domain" = {};

    secrets."pihole/web_password" = {};
    secrets."pangolin/resources/pihole/domain" = {};

    secrets."pangolin/resources/homepage/domain" = {};

    secrets."pangolin/resources/whoami/domain" = {};

    secrets."pangolin/resources/ezbookkeeping/domain" = {};
    secrets."database/postgres/ezbookkeeping/password" = {};
    secrets."finance/ezbookkeeping/secret_key" = {};

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

    secrets."ssh_keys/dobrynikolov" = {};
    secrets."ssh_keys/dobrynikolov.pub" = {};
    secrets."ssh_keys/engineer" = {};
    secrets."ssh_keys/engineer.pub" = {};
  };
}
