{config, ...}: {
  sops.templates."database/sparkyfitness-postgres-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: sparkyfitness-postgres-credentials
        namespace: database
      type: Opaque
      stringData:
        password: ${config.sops.placeholder."database/postgres/sparkyfitness/password"}
        app_password: ${config.sops.placeholder."database/postgres/sparkyfitness/app_password"}
        username: sparky
        app_username: sparkyapp
        database: sparkyfitness
    '';
    path = "/var/lib/rancher/k3s/server/manifests/sparkyfitness-postgres-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
