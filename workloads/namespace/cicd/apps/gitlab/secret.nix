{ config, ... }:

{
  sops.templates = {
    "gitlab/initial-root-password.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: gitlab-initial-root-password
          namespace: cicd
        type: Opaque
        stringData:
          password: "${config.sops.placeholder."gitlab/root_password"}"
      '';
      path = "/var/lib/rancher/k3s/server/manifests/gitlab-initial-root-password.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
    
    "gitlab/postgres-secret.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: gitlab-postgres-secret
          namespace: cicd
        type: Opaque
        stringData:
          password: "${config.sops.placeholder."database/postgres/gitlab/password"}"
      '';
      path = "/var/lib/rancher/k3s/server/manifests/gitlab-postgres-secret.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
    
    "gitlab/minio-connection.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: gitlab-minio-connection
          namespace: cicd
        type: Opaque
        stringData:
          connection: |
            provider: AWS
            region: us-east-1
            aws_access_key_id: ${config.sops.placeholder."database/minio/gitlab/gitlab_access_key"}
            aws_secret_access_key: ${config.sops.placeholder."database/minio/gitlab/gitlab_secret_key"}
            host: minio.database.svc.cluster.local
            endpoint: http://minio.database.svc.cluster.local:9000
            path_style: true
      '';
      path = "/var/lib/rancher/k3s/server/manifests/gitlab-minio-connection.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
    
    "gitlab/registry-storage.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: gitlab-registry-storage
          namespace: cicd
        type: Opaque
        stringData:
          config: |
            s3:
              accesskey: ${config.sops.placeholder."database/minio/gitlab/gitlab_access_key"}
              secretkey: ${config.sops.placeholder."database/minio/gitlab/gitlab_secret_key"}
              bucket: gitlab-registry
              region: us-east-1
              regionendpoint: http://minio.database.svc.cluster.local:9000
              v4auth: true
              secure: false
              pathstyle: true
      '';
      path = "/var/lib/rancher/k3s/server/manifests/gitlab-registry-storage.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
    
    "gitlab/runner-registration-token.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: gitlab-runner-registration-token
          namespace: cicd
        type: Opaque
        stringData:
          runner-token: "${config.sops.placeholder."gitlab/runner_token"}"
          runner-registration-token: "${config.sops.placeholder."gitlab/runner_registration_token"}"
      '';
      path = "/var/lib/rancher/k3s/server/manifests/gitlab-runner-registration-token.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
  };
}
