{ config, ... }:

# Dedicated cert for turn.dobryops.com. The *.dobryops.com wildcard lives
# only in kube-system with no cross-namespace replication, so coturn gets
# its own cert from the same DNS-01 ClusterIssuer (no inbound exposure).
{
  sops.templates."matrix/coturn-certificate.yaml" = {
    content = ''
      apiVersion: cert-manager.io/v1
      kind: Certificate
      metadata:
        name: turn-dobryops-com
        namespace: matrix
      spec:
        secretName: turn-dobryops-com-tls
        issuerRef:
          name: letsencrypt-dns
          kind: ClusterIssuer
        dnsNames:
          - "${config.sops.placeholder."pangolin/resources/turn/domain"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/coturn-certificate.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
