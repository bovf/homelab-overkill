{ ... }:
{
  services.k3s.manifests.minio-apply-public-policy-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "minio-apply-public-policy";
      namespace = "database";
    };
    spec = {
      backoffLimit = 3;
      template = {
        spec = {
          restartPolicy = "Never";
          containers = [
            {
              name = "mc";
              image = "minio/mc:latest";
              imagePullPolicy = "IfNotPresent";
              env = [
                {
                  name = "MINIO_ACCESS_KEY";
                  valueFrom = {
                    secretKeyRef = {
                      name = "minio-credentials";
                      key = "rootUser";
                    };
                  };
                }
                {
                  name = "MINIO_SECRET_KEY";
                  valueFrom = {
                    secretKeyRef = {
                      name = "minio-credentials";
                      key = "rootPassword";
                    };
                  };
                }
              ];
              volumeMounts = [
                { name = "policy"; mountPath = "/policy"; readOnly = true; }
              ];
              command = [ "bash" ];
              args = [
                "-ec"
                ''
                  set -o pipefail
                  endpoint="http://minio.database.svc.cluster.local:9000"

                  # Wait until MinIO is reachable
                  until /usr/bin/mc alias set minio "$endpoint" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" >/dev/null 2>&1; do
                    echo "Waiting for MinIO..."
                    sleep 3
                  done

                  # Create default bucket
                  mc mb --ignore-existing minio/default

                  # Ensure bucket exists (no-op if it already does)
                  /usr/bin/mc mb --ignore-existing minio/default || true

                  # Apply anonymous read policy from JSON (entire bucket)
                  /usr/bin/mc anonymous set-json /policy/policy.json minio/default

                  # Alternatively, the preset:
                  # /usr/bin/mc anonymous set download minio/default
                ''
              ];
              resources = {
                requests = { cpu = "50m"; memory = "64Mi"; };
                limits   = { cpu = "200m"; memory = "128Mi"; };
              };
            }
          ];
          volumes = [
            { name = "policy"; configMap = { name = "minio-default-public-policy"; }; }
          ];
        };
      };
    };
  };
}
