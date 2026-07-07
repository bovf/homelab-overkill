{...}: {
  services.k3s.manifests.postgresql-sparkyfitness-init-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "postgresql-sparkyfitness-init";
      namespace = "database";
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

                psql -h postgresql.database.svc.cluster.local -U postgres <<-EOSQL
                  SELECT 'CREATE DATABASE sparkyfitness'
                  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'sparkyfitness')\gexec

                  DO \$\$
                  BEGIN
                    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'sparky') THEN
                      CREATE USER sparky WITH PASSWORD '$SPARKY_PASSWORD' CREATEROLE;
                    ELSE
                      ALTER USER sparky WITH PASSWORD '$SPARKY_PASSWORD' CREATEROLE;
                    END IF;

                    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'sparkyapp') THEN
                      CREATE USER sparkyapp WITH PASSWORD '$SPARKY_APP_PASSWORD';
                    ELSE
                      ALTER USER sparkyapp WITH PASSWORD '$SPARKY_APP_PASSWORD';
                    END IF;
                  END
                  \$\$;

                  GRANT ALL PRIVILEGES ON DATABASE sparkyfitness TO sparky;
                  GRANT sparkyapp TO sparky;
                  ALTER DATABASE sparkyfitness OWNER TO sparky;

                  \c sparkyfitness
                  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
                  CREATE EXTENSION IF NOT EXISTS "pgcrypto";
                  CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
                  GRANT ALL ON SCHEMA public TO sparky;
                  GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO sparky WITH GRANT OPTION;
                EOSQL

                echo "SparkyFitness database and users are ready."
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
                name = "SPARKY_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "sparkyfitness-postgres-credentials";
                  key = "password";
                };
              }
              {
                name = "SPARKY_APP_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "sparkyfitness-postgres-credentials";
                  key = "app_password";
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
