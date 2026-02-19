{ nodeName, ... }:

{
  workloads.pangolinResources.nzbget = {
    name           = "NZBGet";
    protocol       = "http";
    domainKey      = "pangolin/resources/nzbget/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/nzbget/domain" = {};
}
