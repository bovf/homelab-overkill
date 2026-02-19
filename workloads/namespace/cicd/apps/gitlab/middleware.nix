{ config, ... }:

{
  sops.templates."middleware/gitlab-headers.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: gitlab-headers
        namespace: cicd
      spec:
        headers:
          customRequestHeaders:
            X-Forwarded-Proto: "https"
            X-Forwarded-Port: "443"
            X-Forwarded-Host: "${config.sops.placeholder."pangolin/resources/gitlab/domain"}"
          customResponseHeaders:
            X-Frame-Options: "SAMEORIGIN"
            X-Content-Type-Options: "nosniff"
            X-XSS-Protection: "1; mode=block"
            Referrer-Policy: "strict-origin-when-cross-origin"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/gitlab-middleware.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  sops.templates."middleware/registry-headers.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: registry-headers
        namespace: cicd
      spec:
        headers:
          customRequestHeaders:
            X-Forwarded-Proto: "https"
            X-Forwarded-Port: "443"
            X-Forwarded-Host: "${config.sops.placeholder."pangolin/resources/registry/domain"}"
          customResponseHeaders:
            X-Frame-Options: "SAMEORIGIN"
            X-Content-Type-Options: "nosniff"
            X-XSS-Protection: "1; mode=block"
            Referrer-Policy: "strict-origin-when-cross-origin"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/registry-middleware.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
