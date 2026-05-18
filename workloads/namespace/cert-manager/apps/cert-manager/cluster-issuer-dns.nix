# Wildcard-capable ClusterIssuer using Let's Encrypt DNS-01 with the
# Cloudflare solver. Pairs with the existing http01 `letsencrypt` issuer
# (kept as a fallback for ingress-validated certs).
{ config, ... }:

{
  # Holds the Cloudflare API token cert-manager passes to the DNS-01 solver.
  sops.templates."cert-manager-cloudflare-token.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: cloudflare-api-token-secret
        namespace: cert-manager
      type: Opaque
      stringData:
        api-token: "${config.sops.placeholder."cloudflare/api_token"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/cert-manager-cloudflare-token.yaml";
    owner = "root";
    group = "root";
    mode  = "0600";
  };

  sops.templates."cert-manager-clusterissuer-dns.yaml" = {
    content = ''
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-dns
      spec:
        acme:
          email: "${config.sops.placeholder."admin/email"}"
          server: https://acme-v02.api.letsencrypt.org/directory
          privateKeySecretRef:
            name: letsencrypt-dns
          solvers:
            - dns01:
                cloudflare:
                  apiTokenSecretRef:
                    name: cloudflare-api-token-secret
                    key: api-token
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/cert-manager-clusterissuer-dns.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
