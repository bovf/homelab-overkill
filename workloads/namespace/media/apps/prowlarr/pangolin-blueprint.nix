{ nodeName, ... }:

{
  workloads.pangolinResources.prowlarr = {
    name           = "Prowlarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/prowlarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    healthcheck = {
      hostname = "prowlarr.media.svc.cluster.local";
      port     = 9696;
      path     = "/ping";
    };
  };

  sops.secrets."pangolin/resources/prowlarr/domain" = {};
}
