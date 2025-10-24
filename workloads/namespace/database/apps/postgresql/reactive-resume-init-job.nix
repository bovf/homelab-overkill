{ ... }:

{
  services.k3s.manifests.postgresql-reactive-resume-init-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "postgresql-reactive-resume-init";
      namespace = "database";
    };
    spec = {
      backoffLimit = 3;
      template = {
        spec = {
          restartPolicy = "Never";
          containers = [{
            name = "postgres-init";
            image = "postgres:17-bookworm";
            command = [ "bash" ];
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
                
                # Create Reactive Resume database if it doesn't exist
                psql -h postgresql.database.svc.cluster.local -U postgres <<-EOSQL
                  -- Create database
                  SELECT 'CREATE DATABASE reactive_resumehq_production'
                  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'reactive_resumehq_production')\gexec
                  
                  -- Create user
                  DO \$\$
                  BEGIN
                    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'reactive_resume') THEN
                      CREATE USER reactive_resume WITH PASSWORD '$REACTIVE_RESUME_PASSWORD';
                    END IF;
                  END
                  \$\$;
                  
                  -- Grant privileges
                  GRANT ALL PRIVILEGES ON DATABASE reactive_resumehq_production TO reactive_resume;
                  
                  -- Grant schema privileges
                  \c reactive_resumehq_production
                  GRANT ALL ON SCHEMA public TO reactive_resume;
                  ALTER DATABASE reactive_resumehq_production OWNER TO reactive_resume;
                EOSQL
                
                echo "Reactive Resume database and user created successfully!"
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
                name = "REACTIVE_RESUME_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "reactive-resume-postgres-credentials";
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
          }];
        };
      };
    };
  };
}
