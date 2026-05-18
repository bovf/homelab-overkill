{ nodeName, ... }:

{
  workloads.pangolinResources.homepage = {
    name           = "Homepage";
    protocol       = "http";
    domainKey      = "pangolin/resources/homepage/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "homepage.homepage.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 3000;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.14";
  };

  sops.secrets."pangolin/resources/homepage/domain" = {};
}
