{ nodeName, ... }:

{
  workloads.pangolinResources.radarr = {
    name           = "Radarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/radarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/radarr/domain" = {};
}
