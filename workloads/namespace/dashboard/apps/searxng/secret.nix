# SEARXNG_SECRET signs session cookies + image-proxy URLs. 32 random bytes
# hex'd:  openssl rand -hex 32
{ config, ... }:

{
  sops.templates."searxng/env.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: searxng-env
        namespace: dashboard
      type: Opaque
      stringData:
        SEARXNG_SECRET: "${config.sops.placeholder."searxng/secret"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/searxng-env.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
