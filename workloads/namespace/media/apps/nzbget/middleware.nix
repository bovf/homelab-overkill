{ ... }:

{
  # Traefik Middleware for NZBGet - custom headers and security
  services.k3s.manifests.nzbget-middleware.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "nzbget-headers";
      namespace = "media";
    };
    spec = {
      headers = {
        customRequestHeaders = {
          "X-Forwarded-Proto" = "https";
          "X-Forwarded-Port"  = "443";
          "X-Forwarded-Host"  = "nzbget.dobryops.com";
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
