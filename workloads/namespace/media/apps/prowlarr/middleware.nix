{ config, ... }:

{
  sops.templates."middleware/prowlarr-headers.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: prowlarr-headers
        namespace: media
      spec:
        headers:
          customRequestHeaders:
            X-Forwarded-Proto: "https"
            X-Forwarded-Port: "443"
            X-Forwarded-Host: "${config.sops.placeholder."pangolin/resources/prowlarr/domain"}"
          customResponseHeaders:
            X-Frame-Options: "SAMEORIGIN"
            X-Content-Type-Options: "nosniff"
            X-XSS-Protection: "1; mode=block"
            Referrer-Policy: "strict-origin-when-cross-origin"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/prowlarr-middleware.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
