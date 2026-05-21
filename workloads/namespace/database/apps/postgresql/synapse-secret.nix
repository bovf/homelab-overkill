{ config, ... }:

# database-ns copy of the Synapse DB password, consumed by the
# postgresql-synapse-init Job. Synapse itself reads the same value via
# its node-rendered homeserver.yaml (matrix/apps/synapse/secret.nix).
{
  sops.templates."database/synapse-postgres-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: synapse-postgres-credentials
        namespace: database
      type: Opaque
      stringData:
        password: ${config.sops.placeholder."database/postgres/synapse/password"}
        username: synapse
        database: synapse
        host: postgresql.database.svc.cluster.local
        port: "5432"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/synapse-postgres-credentials.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
