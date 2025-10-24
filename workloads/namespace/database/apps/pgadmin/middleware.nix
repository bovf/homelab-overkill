{ ... }:

{
  services.k3s.manifests.pgadmin-middleware.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "pgadmin-headers";
      namespace = "database";
    };
    spec.headers = {
      customRequestHeaders = {
        X-Forwarded-Proto = "https";
        X-Forwarded-Port = "443";
        X-Forwarded-Host = "pgadmin.dobryops.com";
      };
      customResponseHeaders = {
        X-Frame-Options = "SAMEORIGIN";
        X-Content-Type-Options = "nosniff";
        X-XSS-Protection = "1; mode=block";
        Referrer-Policy = "strict-origin-when-cross-origin";
      };
    };
  };
}
