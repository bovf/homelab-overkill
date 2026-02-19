{ config, ... }:

{
  sops.templates."middleware/minio-headers.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: minio-headers
        namespace: database
      spec:
        headers:
          customRequestHeaders:
            X-Forwarded-Proto: "https"
            X-Forwarded-Port: "443"
            X-Forwarded-Host: "${config.sops.placeholder."pangolin/resources/minio/domain"}"
          customResponseHeaders:
            X-Frame-Options: "SAMEORIGIN"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/minio-middleware.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  sops.templates."middleware/minio-console-headers.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: minio-console-headers
        namespace: database
      spec:
        headers:
          customRequestHeaders:
            X-Forwarded-Proto: "https"
            X-Forwarded-Port: "443"
            X-Forwarded-Host: "${config.sops.placeholder."pangolin/resources/minio_console/domain"}"
          customResponseHeaders:
            X-Frame-Options: "SAMEORIGIN"
            X-Content-Type-Options: "nosniff"
            X-XSS-Protection: "1; mode=block"
            Referrer-Policy: "strict-origin-when-cross-origin"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/minio-console-middleware.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
