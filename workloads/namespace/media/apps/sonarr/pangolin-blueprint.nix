{ nodeName, ... }:

{
  workloads.pangolinResources.sonarr = {
    name           = "Sonarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/sonarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/sonarr/domain" = {};
}
