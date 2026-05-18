{ nodeName, ... }:

{
  workloads.pangolinResources.prowlarr = {
    name           = "Prowlarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/prowlarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "prowlarr.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 9696;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.43";
  };

  sops.secrets."pangolin/resources/prowlarr/domain" = {};
}
