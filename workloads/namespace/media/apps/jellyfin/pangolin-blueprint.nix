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
    targetHostname = "jellyfin.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8096;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.40";
  };

  sops.secrets."pangolin/resources/jellyfin/domain" = {};
}
