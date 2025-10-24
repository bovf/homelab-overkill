{ ... }:

{
  # Middleware for GitLab main application
  services.k3s.manifests.gitlab-middleware.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "gitlab-headers";
      namespace = "cicd";
    };
    spec.headers = {
      customRequestHeaders = {
        X-Forwarded-Proto = "https";
        X-Forwarded-Port = "443";
        X-Forwarded-Host = "gitlab.dobryops.com";
      };
      customResponseHeaders = {
        X-Frame-Options = "SAMEORIGIN";
        X-Content-Type-Options = "nosniff";
        X-XSS-Protection = "1; mode=block";
        Referrer-Policy = "strict-origin-when-cross-origin";
      };
    };
  };

  # Middleware for Container Registry
  services.k3s.manifests.gitlab-registry-middleware.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "registry-headers";
      namespace = "cicd";
    };
    spec.headers = {
      customRequestHeaders = {
        X-Forwarded-Proto = "https";
        X-Forwarded-Port = "443";
        X-Forwarded-Host = "registry.dobryops.com";
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
