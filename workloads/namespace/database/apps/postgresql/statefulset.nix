{ ... }:

{
  services.k3s.manifests.postgresql-statefulset.content = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "postgresql";
      namespace = "database";
      labels.app = "postgresql";
    };
    spec = {
      serviceName = "postgresql";
      replicas = 1;
      selector.matchLabels.app = "postgresql";
      template = {
        metadata.labels.app = "postgresql";
        spec = {
          containers = [{
            name = "postgresql";
            image = "postgres:17-bookworm";
            ports = [{
              containerPort = 5432;
              name = "postgres";
            }];
            env = [
              {
                name = "POSTGRES_DB";
                value = "dobryopsdb";
              }
              {
                name = "POSTGRES_USER";
                value = "postgres";
              }
              {
                name = "POSTGRES_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "postgres-credentials";
                  key = "password";
                };
              }
              {
                name = "PGDATA";
                value = "/var/lib/postgresql/data/pgdata";
              }
            ];
            volumeMounts = [{
              name = "postgres-data";
              mountPath = "/var/lib/postgresql/data";
            }];
            resources = {
              requests = {
                cpu = "250m";
                memory = "512Mi";
              };
              limits = {
                cpu = "1000m";
                memory = "2Gi";
              };
            };
          }];
        };
      };
      volumeClaimTemplates = [{
        metadata.name = "postgres-data";
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "local-path";
          resources.requests.storage = "20Gi";
        };
      }];
    };
  };
}
