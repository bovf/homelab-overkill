{ config, ... }:

{
  sops.templates."reactive-resume-config.yaml" = {
    content = ''
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: reactive-resume-config
        namespace: resume
      data:
        PORT: "3000"
        NODE_ENV: "production"
        PUBLIC_URL: "https://${config.sops.placeholder."pangolin/resources/reactive_resume/domain"}"
        STORAGE_URL: "https://${config.sops.placeholder."pangolin/resources/minio/domain"}/reactive-resume-uploads"
        CHROME_URL: "ws://chrome:3000"
        STORAGE_ENDPOINT: "minio.database.svc.cluster.local"
        STORAGE_PORT: "9000"
        STORAGE_REGION: "eu-central-1"
        STORAGE_BUCKET: "reactive-resume-uploads"
        STORAGE_USE_SSL: "false"
        STORAGE_SKIP_BUCKET_CHECK: "false"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/reactive-resume-config.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
