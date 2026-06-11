{...}: {
  services.k3s.manifests.postgresql-synapse-init-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "postgresql-synapse-init";
      namespace = "database";
    };
    spec = {
      backoffLimit = 3;
      template = {
        spec = {
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

                  # Wait for PostgreSQL to be ready
                  until psql -h postgresql.database.svc.cluster.local -U postgres -c '\q' >/dev/null 2>&1; do
                    echo "Waiting for PostgreSQL..."
                    sleep 3
                  done

                  echo "PostgreSQL is ready!"

                  # Create the synapse role (idempotent)
                  psql -h postgresql.database.svc.cluster.local -U postgres <<-EOSQL
                    DO \$\$
                    BEGIN
                      IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'synapse') THEN
                        CREATE USER synapse WITH PASSWORD '$SYNAPSE_PASSWORD';
                      END IF;
                    END
                    \$\$;
                  EOSQL

                  # Synapse requires its database created with C collation and
                  # UTF8 encoding. CREATE DATABASE can't run conditionally in
                  # SQL, so guard it from the shell instead.
                  if ! psql -h postgresql.database.svc.cluster.local -U postgres -tAc \
                       "SELECT 1 FROM pg_database WHERE datname='synapse'" | grep -q 1; then
                    psql -h postgresql.database.svc.cluster.local -U postgres -c \
                      "CREATE DATABASE synapse WITH OWNER synapse ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0"
                  fi

                  # synapse owns the DB, but make schema privileges explicit
                  psql -h postgresql.database.svc.cluster.local -U postgres -d synapse -c \
                    "GRANT ALL ON SCHEMA public TO synapse"

                  echo "Synapse database and user created successfully!"
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
                  name = "SYNAPSE_PASSWORD";
                  valueFrom.secretKeyRef = {
                    name = "synapse-postgres-credentials";
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
  };
}
