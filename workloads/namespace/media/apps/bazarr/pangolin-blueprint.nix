{ nodeName, ... }:

{
  workloads.pangolinResources.bazarr = {
    name           = "Bazarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/bazarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "bazarr.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 6767;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.42";
  };

  sops.secrets."pangolin/resources/bazarr/domain" = {};
}
