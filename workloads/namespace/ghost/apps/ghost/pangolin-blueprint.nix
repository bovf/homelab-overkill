{ nodeName, ... }:

{
  workloads.pangolinResources.ghost = {
    name           = "Ghost Blog";
    protocol       = "http";
    domainKey      = "pangolin/resources/ghost/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/ghost/domain" = {};
}
