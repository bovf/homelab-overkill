{ ... }:

{
  services.k3s.manifests.mumble-cert.content = {
    apiVersion = "cert-manager.io/v1";
    kind = "Certificate";
    metadata = {
      name = "mumble-tls-cert";
      namespace = "mumble";
    };
    spec = {
      secretName = "mumble-tls-secret";
      issuerRef = {
        name = "letsencrypt";
        kind = "ClusterIssuer";
      };
      dnsNames = [ "mumble.dobryops.com" ];
    };
  };
}
