{ nodeName, ... }:

{
  workloads.pangolinResources.jellyfin = {
    name           = "Jellyfin Media Server";
    protocol       = "http";
    domainKey      = "pangolin/resources/jellyfin/domain";
    enabled        = true;
    ssoEnabled     = true;
    rules          = [
      { priority = 1; action = "allow"; match = "country"; value = "BG"; }
    ];
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    healthcheck = {
      hostname = "jellyfin.media.svc.cluster.local";
      port     = 8096;
      path     = "/health";
    };
  };

  sops.secrets."pangolin/resources/jellyfin/domain" = {};
}
