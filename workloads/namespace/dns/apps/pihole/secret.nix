{ config, ... }:

{
  sops.templates."pihole/secret.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: pihole-web-password
        namespace: dns
      type: Opaque
      stringData:
        password: "${config.sops.placeholder."pihole/web_password"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/pihole-secret.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
