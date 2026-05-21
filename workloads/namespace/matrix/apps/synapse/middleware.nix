{ config, ... }:

{
  sops.templates."middleware/matrix-synapse-headers.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: synapse-headers
        namespace: matrix
      spec:
        headers:
          customRequestHeaders:
            X-Forwarded-Proto: "https"
            X-Forwarded-Port: "443"
            X-Forwarded-Host: "${config.sops.placeholder."pangolin/resources/matrix/domain"}"
          customResponseHeaders:
            X-Content-Type-Options: "nosniff"
            Referrer-Policy: "strict-origin-when-cross-origin"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/matrix-synapse-middleware.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
