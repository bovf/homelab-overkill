{ config, ... }:

{
  sops.templates."database/postgres-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: postgres-credentials
        namespace: database
      type: Opaque
      stringData:
        password: ${config.sops.placeholder."database/postgres/password"}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/postgres-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
