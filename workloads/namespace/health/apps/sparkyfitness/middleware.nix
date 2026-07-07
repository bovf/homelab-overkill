{config, ...}: {
  sops.templates."middleware/sparkyfitness-headers.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: sparkyfitness-headers
        namespace: health
      spec:
        headers:
          customRequestHeaders:
            X-Forwarded-Proto: "https"
            X-Forwarded-Port: "443"
            X-Forwarded-Host: "${config.sops.placeholder."pangolin/resources/sparkyfitness/domain"}"
          customResponseHeaders:
            X-Frame-Options: "SAMEORIGIN"
            X-Content-Type-Options: "nosniff"
            Referrer-Policy: "strict-origin-when-cross-origin"
    '';
    path = "/var/lib/rancher/k3s/server/manifests/sparkyfitness-middleware.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
