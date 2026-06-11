{...}: {
  services.k3s.manifests.postgresql-ezbookkeeping-init-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "postgresql-ezbookkeeping-init";
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

                  # Create ezBookkeeping database if it doesn't exist
                  psql -h postgresql.database.svc.cluster.local -U postgres <<-EOSQL
                    -- Create database
                    SELECT 'CREATE DATABASE ezbookkeeping'
                    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ezbookkeeping')\gexec

                    -- Create user
                    DO \$\$
                    BEGIN
                      IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'ezbookkeeping') THEN
                        CREATE USER ezbookkeeping WITH PASSWORD '$EZBOOKKEEPING_PASSWORD';
                      END IF;
                    END
                    \$\$;

                    -- Grant privileges
                    GRANT ALL PRIVILEGES ON DATABASE ezbookkeeping TO ezbookkeeping;

                    -- Hand the schema to ezbookkeeping so it can auto-migrate
                    \c ezbookkeeping
                    GRANT ALL ON SCHEMA public TO ezbookkeeping;
                    ALTER DATABASE ezbookkeeping OWNER TO ezbookkeeping;
                  EOSQL

                  echo "ezBookkeeping database and user created successfully!"
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
                  name = "EZBOOKKEEPING_PASSWORD";
                  valueFrom.secretKeyRef = {
                    name = "ezbookkeeping-postgres-credentials";
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
