{ ... }:

{
  services.k3s.manifests.minio-headers.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "minio-headers";
      namespace = "database";
    };
    spec.headers = {
      customRequestHeaders = {
        X-Forwarded-Proto = "https";
        X-Forwarded-Port = "443";
        X-Forwarded-Host = "minio.dobryops.com";
      };
      customResponseHeaders = {
        X-Frame-Options = "SAMEORIGIN";
      };
    };
  };

  services.k3s.manifests.minio-console-headers.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "minio-console-headers";
      namespace = "database";
    };
    spec.headers = {
      customRequestHeaders = {
        X-Forwarded-Proto = "https";
        X-Forwarded-Port = "443";
        X-Forwarded-Host = "minio-console.dobryops.com";
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
