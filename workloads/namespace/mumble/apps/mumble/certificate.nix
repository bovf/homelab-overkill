{ config, ... }:

{
  sops.templates."mumble-certificate.yaml" = {
    content = ''
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: mumble-tls-cert
        namespace: mumble
      spec:
        secretName: mumble-tls-secret
        issuerRef:
          name: letsencrypt
          kind: ClusterIssuer
        dnsNames:
          - "${config.sops.placeholder."pangolin/resources/mumble/domain"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/mumble-certificate.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
