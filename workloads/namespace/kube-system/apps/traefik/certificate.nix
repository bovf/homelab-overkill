# Wildcard cert for *.dobryops.com, issued via the DNS-01 ClusterIssuer
# and consumed by traefik as its default TLS certificate (see helm.nix
# `tlsStore.default`).
{ ... }:

{
  services.k3s.manifests.traefik-wildcard-cert.content = {
    apiVersion = "cert-manager.io/v1";
    kind       = "Certificate";
    metadata = {
      name      = "wildcard-dobryops-com";
      namespace = "kube-system";
    };
    spec = {
      secretName = "wildcard-dobryops-com-tls";
      issuerRef = {
        name = "letsencrypt-dns";
        kind = "ClusterIssuer";
      };
      dnsNames = [
        "*.dobryops.com"
        "dobryops.com"
      ];
    };
  };
}
