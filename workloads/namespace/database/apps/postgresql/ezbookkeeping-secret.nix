{ config, ... }:

# database-ns copy of the ezbookkeeping DB password, consumed by the
# postgresql-ezbookkeeping-init Job. The finance-ns app reads the same
# value from its own ezbookkeeping-credentials secret.
{
  sops.templates."database/ezbookkeeping-postgres-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: ezbookkeeping-postgres-credentials
        namespace: database
      type: Opaque
      stringData:
        password: ${config.sops.placeholder."database/postgres/ezbookkeeping/password"}
        username: ezbookkeeping
        database: ezbookkeeping
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/ezbookkeeping-postgres-credentials.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
