{...}: {
  services.k3s.manifests.minio-loki-init.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "minio-loki-init";
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
              image = "minio/mc:RELEASE.2025-08-13T08-35-41Z-cpuv1";
              command = ["bash"];
              args = [
                "-ec"
                ''
                  set -o pipefail

                  until mc alias set minio http://minio.database.svc.cluster.local:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; do
                    echo "Waiting for MinIO..."
                    sleep 3
                  done

                  echo "MinIO is ready!"

                  mc mb --ignore-existing minio/loki-chunks

                  mc admin user add minio "$LOKI_ACCESS_KEY" "$LOKI_SECRET_KEY" || true

                  cat > /tmp/loki-policy.json <<EOF
                  {
                    "Version": "2012-10-17",
                    "Statement": [
                      {
                        "Effect": "Allow",
                        "Action": [
                          "s3:*"
                        ],
                        "Resource": [
                          "arn:aws:s3:::loki-chunks",
                          "arn:aws:s3:::loki-chunks/*"
                        ]
                      }
                    ]
                  }
                  EOF

                  mc admin policy create minio loki-policy /tmp/loki-policy.json || true
                  mc admin policy attach minio loki-policy --user "$LOKI_ACCESS_KEY"

                  echo "Loki MinIO user, bucket, and policy configured!"
                ''
              ];
              env = [
                {
                  name = "MINIO_ROOT_USER";
                  valueFrom.secretKeyRef = {
                    name = "minio-credentials";
                    key = "rootUser";
                  };
                }
                {
                  name = "MINIO_ROOT_PASSWORD";
                  valueFrom.secretKeyRef = {
                    name = "minio-credentials";
                    key = "rootPassword";
                  };
                }
                {
                  name = "LOKI_ACCESS_KEY";
                  valueFrom.secretKeyRef = {
                    name = "loki-minio-credentials";
                    key = "access-key";
                  };
                }
                {
                  name = "LOKI_SECRET_KEY";
                  valueFrom.secretKeyRef = {
                    name = "loki-minio-credentials";
                    key = "secret-key";
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
                  memory = "512Mi";
                };
              };
            }
          ];
        };
      };
    };
  };
}
