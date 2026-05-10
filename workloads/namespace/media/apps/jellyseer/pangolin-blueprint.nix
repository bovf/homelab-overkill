{ nodeName, ... }:

{
  workloads.pangolinResources.jellyseerr = {
    name           = "Jellyseerr";
    protocol       = "http";
    domainKey      = "pangolin/resources/jellyseerr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    healthcheck = {
      # Service port is 5055 (matches the app's internal listener), not 80.
      hostname = "jellyseerr.media.svc.cluster.local";
      port     = 5055;
      path     = "/";
    };
  };

  sops.secrets."pangolin/resources/jellyseerr/domain" = {};
}
