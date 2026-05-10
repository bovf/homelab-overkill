{ nodeName, ... }:

{
  # MinIO API endpoint
  workloads.pangolinResources.minio = {
    name           = "MinIO Object Storage";
    protocol       = "http";
    domainKey      = "pangolin/resources/minio/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/minio/domain" = {};

  # MinIO Console (separate subdomain served via consoleIngress)
  workloads.pangolinResources.minio_console = {
    name           = "MinIO Console";
    protocol       = "http";
    domainKey      = "pangolin/resources/minio_console/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/minio_console/domain" = {};
}
