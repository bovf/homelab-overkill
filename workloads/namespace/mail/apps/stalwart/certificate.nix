# Issues a wildcard *.dobryops.com cert into the mail namespace via the
# DNS-01 ClusterIssuer. Mirrors the kube-system Certificate that traefik
# consumes — separate copy because cert-manager Secrets are namespace-
# scoped and no reflector controller is installed.
{ ... }:

{
  services.k3s.manifests.mail-wildcard-cert.content = {
    apiVersion = "cert-manager.io/v1";
    kind       = "Certificate";
    metadata = {
      name      = "wildcard-dobryops-com";
      namespace = "mail";
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
