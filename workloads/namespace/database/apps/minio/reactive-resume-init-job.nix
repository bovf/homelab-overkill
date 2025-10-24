{ ... }:

{
  services.k3s.manifests.reactive-resume-minio-init-job = {
    content = {
      apiVersion = "batch/v1";
      kind = "Job";
      metadata = {
        name = "reactive-resume-minio-init";
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
                    name = "SCOPED_ACCESS_KEY";
                    valueFrom.secretKeyRef = {
                      name = "reactive-resume-minio-credentials";
                      key = "SCOPED_ACCESS_KEY";
                    };
                  }
                  {
                    name = "SCOPED_SECRET_KEY";
                    valueFrom.secretKeyRef = {
                      name = "reactive-resume-minio-credentials";
                      key = "SCOPED_SECRET_KEY";
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
                    
                    MINIO_ENDPOINT="http://minio.database.svc.cluster.local:9000"
                    
                    # Wait for MinIO to be ready
                    until /usr/bin/mc alias set minio "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" > /dev/null 2>&1; do
                      echo "Waiting for MinIO at $MINIO_ENDPOINT..."
                      sleep 3
                    done
                    
                    echo "MinIO is ready!"
                    
                    # Create buckets if they don't exist
                    echo "Creating Reactive Resume buckets..."
                    /usr/bin/mc mb --ignore-existing minio/reactive-resume-uploads
                    /usr/bin/mc mb --ignore-existing minio/reactive-resume-resumes
                    echo "Buckets ensured!"
                    
                    # Create scoped user if it doesn't exist
                    echo "Setting up Reactive Resume scoped user..."
                    /usr/bin/mc admin user add minio "$SCOPED_ACCESS_KEY" "$SCOPED_SECRET_KEY" 2>&1 || true
                    echo "User setup complete!"
                    
                    # Create and attach policy
                    echo "Applying Reactive Resume policy..."
                    /usr/bin/mc admin policy create minio reactive-resume-policy /policy/policy.json 2>&1 || true
                    /usr/bin/mc admin policy attach minio reactive-resume-policy --user "$SCOPED_ACCESS_KEY"
                    echo "Policy attached!"
                    
                    # Make bucket publicly readable (for browser image access)
                    echo "Setting public read access for reactive-resume-uploads..."
                    /usr/bin/mc anonymous set download minio/reactive-resume-uploads
                    echo "Public access enabled!"
                    
                    echo "Reactive Resume MinIO initialization complete!"
                  ''
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
            
            volumes = [
              {
                name = "policy";
                configMap = {
                  name = "reactive-resume-minio-policy";
                };
              }
            ];
          };
        };
      };
    };
  };
}
