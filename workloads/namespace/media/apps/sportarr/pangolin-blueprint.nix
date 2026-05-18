{ nodeName, ... }:

{
  workloads.pangolinResources.sportarr = {
    name           = "Sportarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/sportarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "sportarr.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 1867;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.46";
  };

  sops.secrets."pangolin/resources/sportarr/domain" = {};
}
