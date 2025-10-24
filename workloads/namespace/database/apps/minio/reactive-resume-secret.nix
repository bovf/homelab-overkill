{ config, ... }:

{
  sops.templates."database/reactive-resume-minio-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: reactive-resume-minio-credentials
        namespace: database
      type: Opaque
      stringData:
        SCOPED_ACCESS_KEY: ${config.sops.placeholder."database/minio/reactive_resume/reactive_resume_access_key"}
        SCOPED_SECRET_KEY: ${config.sops.placeholder."database/minio/reactive_resume/reactive_resume_secret_key"}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/reactive-resume-minio-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
