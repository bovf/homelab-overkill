{ ... }:

# Traefik middleware to ensure correct forwarded headers for qBittorrent
# Adjust the host name if you change the ingress host
{
  services.k3s.manifests.qbittorrent-middleware.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind       = "Middleware";
    metadata = {
      name      = "qbittorrent-headers";
      namespace = "media";
    };
    spec = {
      headers = {
        customRequestHeaders = {
          "X-Forwarded-Proto" = "https";
          "X-Forwarded-Port"  = "443";
          "X-Forwarded-Host"  = "qbittorrent.dobryops.com";
        };
        customResponseHeaders = {
          "X-Frame-Options"          = "SAMEORIGIN";
          "X-Content-Type-Options"   = "nosniff";
          "X-XSS-Protection"        = "1; mode=block";
          "Referrer-Policy"         = "strict-origin-when-cross-origin";
        };
      };
    };
  };
}
