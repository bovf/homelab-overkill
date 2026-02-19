{ nodeName, ... }:

{
  workloads.pangolinResources.jellyfin = {
    name           = "Jellyfin Media Server";
    protocol       = "http";
    domainKey      = "pangolin/resources/jellyfin/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/jellyfin/domain" = {};
}
