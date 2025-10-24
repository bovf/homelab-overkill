{ ... }:

{
  services.k3s.manifests.postgresql-gitlab-init-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "postgresql-gitlab-init";
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
                
                # Create GitLab database if it doesn't exist
                psql -h postgresql.database.svc.cluster.local -U postgres <<-EOSQL
                  -- Create database
                  SELECT 'CREATE DATABASE gitlabhq_production'
                  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gitlabhq_production')\gexec
                  
                  -- Create user
                  DO \$\$
                  BEGIN
                    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'gitlab') THEN
                      CREATE USER gitlab WITH PASSWORD '$GITLAB_PASSWORD';
                    END IF;
                  END
                  \$\$;
                  
                  -- Grant privileges
                  GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production TO gitlab;
                  
                  -- Grant schema privileges
                  \c gitlabhq_production
                  GRANT ALL ON SCHEMA public TO gitlab;
                  ALTER DATABASE gitlabhq_production OWNER TO gitlab;
                EOSQL
                
                echo "GitLab database and user created successfully!"
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
                name = "GITLAB_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "gitlab-postgres-credentials";
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
