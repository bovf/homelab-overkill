{ config, ... }:

{
  sops.templates."database/gitlab-minio-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: gitlab-minio-credentials
        namespace: database
      type: Opaque
      stringData:
        access-key: ${config.sops.placeholder."database/minio/gitlab/gitlab_access_key"}
        secret-key: ${config.sops.placeholder."database/minio/gitlab/gitlab_secret_key"}
        endpoint: "http://minio.database.svc.cluster.local:9000"
        region: "eu-central-1"
    '';
    path = "/var/lib/rancher/k3s/server/manifests/gitlab-minio-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
