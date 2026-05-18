{ nodeName, ... }:

{
  workloads.pangolinResources.nzbget = {
    name           = "NZBGet";
    protocol       = "http";
    domainKey      = "pangolin/resources/nzbget/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "nzbget.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 6789;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.47";
  };

  sops.secrets."pangolin/resources/nzbget/domain" = {};
}
