{ config, ... }:

{
  sops.templates."middleware/argocd-headers.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: argocd-headers
        namespace: cicd
      spec:
        headers:
          customRequestHeaders:
            X-Forwarded-Proto: "https"
            X-Forwarded-Port: "443"
            X-Forwarded-Host: "${config.sops.placeholder."pangolin/resources/argocd/domain"}"
          customResponseHeaders:
            X-Frame-Options: "SAMEORIGIN"
            X-Content-Type-Options: "nosniff"
            X-XSS-Protection: "1; mode=block"
            Referrer-Policy: "strict-origin-when-cross-origin"
          sslRedirect: true
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/argocd-middleware.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
