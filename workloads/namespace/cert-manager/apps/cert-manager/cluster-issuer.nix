{ ... }:

{
  services.k3s.manifests.cert-manager-clusterissuer-prod.content = {
    apiVersion = "cert-manager.io/v1";
    kind = "ClusterIssuer";
    metadata = { name = "letsencrypt"; };
    spec = {
      acme = {
        email = "dobry@dobryops.com";
        server = "https://acme-v02.api.letsencrypt.org/directory";
        privateKeySecretRef = { name = "letsencrypt"; };
        solvers = [
          {
            http01 = {
              ingress = {
                class = "traefik";
              };
            };
          }
        ];
      };
    };
  };
}
