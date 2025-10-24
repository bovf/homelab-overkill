{ config, ... }:

{
  sops.templates."database/minio-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: minio-credentials
        namespace: database
      type: Opaque
      stringData:
        rootUser: ${config.sops.placeholder."database/minio/root_user"}
        rootPassword: ${config.sops.placeholder."database/minio/root_password"}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/minio-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
