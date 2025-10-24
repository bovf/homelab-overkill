{ config, ... }:

{
  sops.templates."database/pgadmin-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: pgadmin-credentials
        namespace: database
      type: Opaque
      stringData:
        email: "${config.sops.placeholder."database/pgadmin/email"}"
        password: "${config.sops.placeholder."database/pgadmin/password"}"
    '';
    path = "/var/lib/rancher/k3s/server/manifests/pgadmin-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
