{ ... }:

{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];
    age.generateKey = true;

    # ------------------------------------------------------------------
    # Pangolin instances (one block per node / newt deployment)
    # ------------------------------------------------------------------
    # engineer node
    secrets."pangolin/instances/engineer/endpoint"    = {};
    secrets."pangolin/instances/engineer/newt_id"     = {};
    secrets."pangolin/instances/engineer/newt_secret" = {};
    secrets."pangolin/instances/engineer/site_id"     = {};

    # ------------------------------------------------------------------
    # Pangolin resource domains (one per exposed service)
    # ------------------------------------------------------------------
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
    secrets."pangolin/resources/minio/domain"            = {};
    secrets."pangolin/resources/minio_console/domain"    = {};
    secrets."pangolin/resources/pgadmin/domain"          = {};
    secrets."pangolin/resources/gitlab/domain"           = {};
    secrets."pangolin/resources/registry/domain"         = {};
    secrets."pangolin/resources/postgres/domain"         = {};
    secrets."pangolin/resources/mumble/domain"           = {};
    secrets."pangolin/resources/reactive_resume/domain"  = {};
    secrets."pangolin/resources/traefik_dashboard/domain" = {};

    # ------------------------------------------------------------------
    # Pangolin resource ports (TCP tunnels)
    # Ports are used by sops.placeholder in the blueprint renderer.
    # Domains for engineer_ssh and engineer_k8s_api are NOT declared here
    # because they are only consumed at runtime by nix apps (via sops
    # --decrypt + yq), not by sops-nix on the node.
    # ------------------------------------------------------------------
    secrets."pangolin/resources/engineer_ssh/port"         = {};
    secrets."pangolin/resources/engineer_k8s_api/port"     = {};
    secrets."pangolin/resources/gitlab_ssh/port"           = {};

    # ------------------------------------------------------------------
    # Admin / shared
    # ------------------------------------------------------------------
    secrets."admin/base_domain" = {};
    secrets."admin/email"       = {};

    # ------------------------------------------------------------------
    # NZBGet credentials
    # ------------------------------------------------------------------
    secrets."media/nzbget/username" = {};
    secrets."media/nzbget/password" = {};

    secrets."qbittorrent/password_hash" = {};
    secrets."qbittorrent/password" = {};

    secrets."monitoring/grafana-admin-password" = {};

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
    secrets."database/postgres/reactive_resume/password" = {};
    secrets."database/pgadmin/email" = {};
    secrets."database/pgadmin/password" = {};
    secrets."database/minio/root_user" = {};
    secrets."database/minio/root_password" = {};
    secrets."database/minio/gitlab/gitlab_access_key" = {};
    secrets."database/minio/gitlab/gitlab_secret_key" = {};
    secrets."database/minio/reactive_resume/reactive_resume_access_key" = {};
    secrets."database/minio/reactive_resume/reactive_resume_secret_key" = {};

    secrets."gitlab/root_password" = {};
    secrets."gitlab/runner_token" = {};
    secrets."gitlab/runner_registration_token" = {};

    secrets."argocd/admin_password" = {};
    secrets."argocd/gitlab_token" = {};
    secrets."pangolin/resources/argocd/domain" = {};

    secrets."pihole/web_password" = {};
    secrets."pangolin/resources/pihole/domain" = {};

    secrets."pangolin/resources/homepage/domain" = {};

    secrets."pangolin/resources/ghost/domain" = {};

    secrets."reactive_resume/chrome_token" = {};
    secrets."reactive_resume/access_token_secret" = {};
    secrets."reactive_resume/refresh_token_secret" = {};

    secrets."ssh_keys/dobrynikolov" = {};
    secrets."ssh_keys/dobrynikolov.pub" = {};
    secrets."ssh_keys/engineer" = {};
    secrets."ssh_keys/engineer.pub" = {};
  };
}
