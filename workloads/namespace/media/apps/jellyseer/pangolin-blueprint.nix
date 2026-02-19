{ nodeName, ... }:

{
  workloads.pangolinResources.jellyseerr = {
    name           = "Jellyseerr";
    protocol       = "http";
    domainKey      = "pangolin/resources/jellyseerr/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/jellyseerr/domain" = {};
}
