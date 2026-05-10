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
    healthcheck = {
      hostname = "minio.database.svc.cluster.local";
      port     = 9000;
      path     = "/minio/health/live";
    };
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
    healthcheck = {
      # The console runs on its own Service (`minio-console`, not the
      # `minio` API service). It has no dedicated health endpoint but
      # /login returns the SPA shell with 200 OK.
      hostname = "minio-console.database.svc.cluster.local";
      port     = 9001;
      path     = "/login";
    };
  };

  sops.secrets."pangolin/resources/minio_console/domain" = {};
}
