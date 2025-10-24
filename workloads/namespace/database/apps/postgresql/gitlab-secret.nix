{ config, ... }:

{
  sops.templates."database/gitlab-postgres-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: gitlab-postgres-credentials
        namespace: database
      type: Opaque
      stringData:
        password: ${config.sops.placeholder."database/postgres/gitlab/password"}
        username: gitlab
        database: gitlabhq_production
        host: postgresql.database.svc.cluster.local
        port: "5432"
    '';
    path = "/var/lib/rancher/k3s/server/manifests/gitlab-postgres-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
