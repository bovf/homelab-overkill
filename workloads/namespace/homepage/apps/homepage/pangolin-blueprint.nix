{ nodeName, ... }:

{
  workloads.pangolinResources.homepage = {
    name           = "Homepage";
    protocol       = "http";
    domainKey      = "pangolin/resources/homepage/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    healthcheck = {
      hostname = "homepage.homepage.svc.cluster.local";
      port     = 3000;
      path     = "/";
    };
  };

  sops.secrets."pangolin/resources/homepage/domain" = {};
}
