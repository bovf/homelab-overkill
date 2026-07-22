# Media namespace entrypoint
{...}: {
  imports = [
    # Import apps with their entrypoints
    ./apps/bazarr
    ./apps/gamarr
    ./apps/jellyfin
    ./apps/jellyseer
    ./apps/prowlarr
    ./apps/qbittorrent
    ./apps/radarr
    ./apps/sonarr
    ./apps/nzbget
    ./apps/romm
    ./apps/sportarr

    # Import namespace specific definitions
    ./shared
  ];

  # Define k3s namespace manifest
  services.k3s.manifests.media-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {name = "media";};
  };
}
