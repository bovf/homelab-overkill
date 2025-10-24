{ ... }:

{
  services.k3s.manifests.minio-gitlab-init-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "minio-gitlab-init";
      namespace = "database";
    };
    spec = {
      backoffLimit = 3;
      template = {
        spec = {
          restartPolicy = "Never";
          containers = [{
            name = "mc";
            image = "minio/mc:latest";
            command = [ "bash" ];
            args = [
              "-ec"
              ''
                set -o pipefail
                
                # Wait for MinIO to be ready
                until mc alias set minio http://minio.database.svc.cluster.local:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; do
                  echo "Waiting for MinIO..."
                  sleep 3
                done
                
                echo "MinIO is ready!"
                
                # Create GitLab buckets
                mc mb --ignore-existing minio/gitlab-artifacts
                mc mb --ignore-existing minio/gitlab-lfs
                mc mb --ignore-existing minio/gitlab-uploads
                mc mb --ignore-existing minio/gitlab-packages
                mc mb --ignore-existing minio/gitlab-registry
                mc mb --ignore-existing minio/gitlab-backups
                mc mb --ignore-existing minio/gitlab-tmp
                
                echo "Buckets created!"
                
                # Create GitLab user with access/secret keys
                mc admin user add minio "$GITLAB_ACCESS_KEY" "$GITLAB_SECRET_KEY" || true
                
                # Create policy for GitLab buckets
                cat > /tmp/gitlab-policy.json <<EOF
                {
                  "Version": "2012-10-17",
                  "Statement": [
                    {
                      "Effect": "Allow",
                      "Action": [
                        "s3:*"
                      ],
                      "Resource": [
                        "arn:aws:s3:::gitlab-artifacts",
                        "arn:aws:s3:::gitlab-artifacts/*",
                        "arn:aws:s3:::gitlab-lfs",
                        "arn:aws:s3:::gitlab-lfs/*",
                        "arn:aws:s3:::gitlab-uploads",
                        "arn:aws:s3:::gitlab-uploads/*",
                        "arn:aws:s3:::gitlab-packages",
                        "arn:aws:s3:::gitlab-packages/*",
                        "arn:aws:s3:::gitlab-registry",
                        "arn:aws:s3:::gitlab-registry/*",
                        "arn:aws:s3:::gitlab-backups",
                        "arn:aws:s3:::gitlab-backups/*",
                        "arn:aws:s3:::gitlab-tmp",
                        "arn:aws:s3:::gitlab-tmp/*"
                      ]
                    }
                  ]
                }
                EOF
                
                # Apply policy
                mc admin policy create minio gitlab-policy /tmp/gitlab-policy.json || true
                mc admin policy attach minio gitlab-policy --user "$GITLAB_ACCESS_KEY"
                
                echo "GitLab MinIO user and buckets configured successfully!"
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
                name = "GITLAB_ACCESS_KEY";
                valueFrom.secretKeyRef = {
                  name = "gitlab-minio-credentials";
                  key = "access-key";
                };
              }
              {
                name = "GITLAB_SECRET_KEY";
                valueFrom.secretKeyRef = {
                  name = "gitlab-minio-credentials";
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
          }];
        };
      };
    };
  };
}

