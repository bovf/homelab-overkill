{ ... }:

{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/root/.ssh/id_ed25519" ];
    age.generateKey = true;

    secrets."pangolin/newt_id" = {};
    secrets."pangolin/newt_secret" = {};

    secrets."nordvpn/wireguard_private_key" = {};
    secrets."nordvpn/username" = {};
    secrets."nordvpn/password" = {};

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

    secrets."reactive_resume/chrome_token" = {};
    secrets."reactive_resume/access_token_secret" = {};
    secrets."reactive_resume/refresh_token_secret" = {};

    secrets."ssh_keys/dobrynikolov" = {};
    secrets."ssh_keys/dobrynikolov.pub" = {};
    secrets."ssh_keys/engineer" = {};
    secrets."ssh_keys/engineer.pub" = {};
  };
}
