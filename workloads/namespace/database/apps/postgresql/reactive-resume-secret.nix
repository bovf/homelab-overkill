{ config, ... }:

{
  sops.templates."database/reactive-resume-postgres-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: reactive-resume-postgres-credentials
        namespace: database
      type: Opaque
      stringData:
        password: ${config.sops.placeholder."database/postgres/reactive_resume/password"}
        username: reactive_resume
        database: reactive_resumehq_production
        host: postgresql.database.svc.cluster.local
        port: "5432"
    '';
    path = "/var/lib/rancher/k3s/server/manifests/reactive-resume-postgres-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
