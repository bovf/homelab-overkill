{ ... }:

{
  sops.templates."pihole/secret.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: pihole-secret
        namespace: dns
      type: Opaque
      stringData:
        # Change this to your desired admin password
        WEBPASSWORD: "ChangeMe123!PiholeAdminPassword"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/pihole-secret.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
