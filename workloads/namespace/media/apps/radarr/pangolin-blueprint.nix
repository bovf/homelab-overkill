{ nodeName, ... }:

{
  workloads.pangolinResources.radarr = {
    name           = "Radarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/radarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "radarr.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 7878;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.44";
  };

  sops.secrets."pangolin/resources/radarr/domain" = {};
}
