{ ... }:

{
  workloads.pangolinResources.search = {
    name           = "SearXNG";
    protocol       = "http";
    domainKey      = "pangolin/resources/search/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "searxng.dashboard.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8098;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.74";
  };

  sops.secrets."pangolin/resources/search/domain" = {};
}
