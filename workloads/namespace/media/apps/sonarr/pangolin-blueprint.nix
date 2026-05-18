{ nodeName, ... }:

{
  workloads.pangolinResources.sonarr = {
    name           = "Sonarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/sonarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "sonarr.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8989;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.45";
  };

  sops.secrets."pangolin/resources/sonarr/domain" = {};
}
