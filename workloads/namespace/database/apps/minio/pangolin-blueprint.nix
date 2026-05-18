{ nodeName, ... }:

{
  # MinIO API endpoint
  workloads.pangolinResources.minio = {
    name           = "MinIO Object Storage";
    protocol       = "http";
    domainKey      = "pangolin/resources/minio/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "minio.database.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 9000;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.11";
  };

  sops.secrets."pangolin/resources/minio/domain" = {};

  # MinIO Console (separate subdomain served via consoleIngress)
  workloads.pangolinResources.minio_console = {
    name           = "MinIO Console";
    protocol       = "http";
    domainKey      = "pangolin/resources/minio_console/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "minio-console.database.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 9001;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.12";
  };

  sops.secrets."pangolin/resources/minio_console/domain" = {};
}
