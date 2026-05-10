{ nodeName, ... }:

{
  workloads.pangolinResources.sportarr = {
    name           = "Sportarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/sportarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    healthcheck = {
      hostname = "sportarr.media.svc.cluster.local";
      port     = 1867;
      path     = "/";
    };
  };

  sops.secrets."pangolin/resources/sportarr/domain" = {};
}
