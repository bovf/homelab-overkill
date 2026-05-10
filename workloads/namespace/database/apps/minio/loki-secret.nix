{ config, ... }:

{
  sops.templates."database/loki-minio-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: loki-minio-credentials
        namespace: database
      type: Opaque
      stringData:
        access-key: ${config.sops.placeholder."database/minio/loki/access_key"}
        secret-key: ${config.sops.placeholder."database/minio/loki/secret_key"}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/loki-minio-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
