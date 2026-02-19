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
  };

  sops.secrets."pangolin/resources/prowlarr/domain" = {};
}
