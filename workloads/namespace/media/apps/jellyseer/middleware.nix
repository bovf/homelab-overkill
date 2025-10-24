{ ... }:

{
  # Jellyseerr Traefik middleware
  services.k3s.manifests.jellyseerr-middleware.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "jellyseerr-headers";
      namespace = "media";
    };
    spec = {
      headers = {
        customRequestHeaders = {
          "X-Forwarded-Proto" = "https";
          "X-Forwarded-Port" = "443";
          "X-Forwarded-Host" = "jellyseerr.dobryops.com";
        };
        customResponseHeaders = {
          "X-Frame-Options" = "SAMEORIGIN";
          "X-Content-Type-Options" = "nosniff";
          "X-XSS-Protection" = "1; mode=block";
          "Referrer-Policy" = "strict-origin-when-cross-origin";
        };
      };
    };
  };
}
