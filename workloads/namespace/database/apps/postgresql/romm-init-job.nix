{...}: let
  # Bump with database/postgres/romm/password so Kubernetes creates a new
  # immutable Job and runs the idempotent ALTER ROLE before RomM restarts.
  initVersion = "1";
in {
  services.k3s.manifests.postgresql-romm-init-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "postgresql-romm-init-v${initVersion}";
      namespace = "database";
      annotations."homelab.dobryops.com/init-version" = initVersion;
    };
    spec = {
      backoffLimit = 3;
      template.spec = {
        restartPolicy = "Never";
        containers = [
          {
            name = "postgres-init";
            image = "postgres:17.10-bookworm";
            command = ["bash"];
            args = [
              "-ec"
              ''
                set -o pipefail

                until psql -h postgresql.database.svc.cluster.local -U postgres -c '\q' >/dev/null 2>&1; do
                  echo "Waiting for PostgreSQL..."
                  sleep 3
                done

                psql -v ON_ERROR_STOP=1 \
                  --host=postgresql.database.svc.cluster.local \
                  --username=postgres \
                  --set=romm_password="$ROMM_PASSWORD" <<'EOSQL'
                  SELECT format('CREATE ROLE romm LOGIN PASSWORD %L', :'romm_password')
                  WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'romm')\gexec

                  SELECT format('ALTER ROLE romm WITH LOGIN PASSWORD %L', :'romm_password')\gexec

                  SELECT 'CREATE DATABASE romm OWNER romm'
                  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'romm')\gexec

                  ALTER DATABASE romm OWNER TO romm;
                  GRANT ALL PRIVILEGES ON DATABASE romm TO romm;

                  \connect romm
                  ALTER SCHEMA public OWNER TO romm;
                  GRANT ALL ON SCHEMA public TO romm;
                EOSQL

                echo "RomM database and role are ready."
              ''
            ];
            env = [
              {
                name = "PGPASSWORD";
                valueFrom.secretKeyRef = {
                  name = "postgres-credentials";
                  key = "password";
                };
              }
              {
                name = "ROMM_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "romm-postgres-credentials";
                  key = "password";
                };
              }
            ];
            resources = {
              requests = {
                cpu = "50m";
                memory = "64Mi";
              };
              limits = {
                cpu = "200m";
                memory = "128Mi";
              };
            };
          }
        ];
      };
    };
  };
}
