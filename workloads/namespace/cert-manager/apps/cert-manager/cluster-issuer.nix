{ config, ... }:

{
  sops.templates."cert-manager-clusterissuer.yaml" = {
    content = ''
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt
      spec:
        acme:
          email: "${config.sops.placeholder."admin/email"}"
          server: https://acme-v02.api.letsencrypt.org/directory
          privateKeySecretRef:
            name: letsencrypt
          solvers:
            - http01:
                ingress:
                  class: traefik
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/cert-manager-clusterissuer.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
