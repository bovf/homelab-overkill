{ config, ... }:

{
  sops.templates."resume/reactive-resume-secrets.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: reactive-resume-secrets
        namespace: resume
      type: Opaque
      stringData:
        # App authentication secrets
        ACCESS_TOKEN_SECRET: ${config.sops.placeholder."reactive_resume/access_token_secret"}
        REFRESH_TOKEN_SECRET: ${config.sops.placeholder."reactive_resume/refresh_token_secret"}
        
        # Browserless Chrome token
        CHROME_TOKEN: ${config.sops.placeholder."reactive_resume/chrome_token"}
        
        # Database connection (PostgreSQL in 'database' namespace)
        DATABASE_URL: "postgresql://reactive_resume:${config.sops.placeholder."database/postgres/reactive_resume/password"}@postgresql.database.svc.cluster.local:5432/reactive_resumehq_production"
        
        # MinIO credentials (scoped user)
        STORAGE_ACCESS_KEY: ${config.sops.placeholder."database/minio/reactive_resume/reactive_resume_access_key"}
        STORAGE_SECRET_KEY: ${config.sops.placeholder."database/minio/reactive_resume/reactive_resume_secret_key"}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/reactive-resume-app-secrets.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
