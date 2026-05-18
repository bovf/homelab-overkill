{ nodeName, ... }:

{
  workloads.pangolinResources.jellyseerr = {
    name           = "Jellyseerr";
    protocol       = "http";
    domainKey      = "pangolin/resources/jellyseerr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "jellyseerr.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 5055;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.41";
  };

  sops.secrets."pangolin/resources/jellyseerr/domain" = {};
}
