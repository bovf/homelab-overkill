{config, ...}: {
  sops.templates."database/romm-postgres-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: romm-postgres-credentials
        namespace: database
      type: Opaque
      stringData:
        password: "${config.sops.placeholder."database/postgres/romm/password"}"
        username: romm
        database: romm
    '';
    path = "/var/lib/rancher/k3s/server/manifests/romm-postgres-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
