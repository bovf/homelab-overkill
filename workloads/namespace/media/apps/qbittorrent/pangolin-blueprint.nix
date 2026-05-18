{ nodeName, ... }:

{
  workloads.pangolinResources.qbittorrent = {
    name           = "qBittorrent VPN";
    protocol       = "http";
    domainKey      = "pangolin/resources/qbittorrent/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "qbittorrent.media.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8080;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.48";
  };

  sops.secrets."pangolin/resources/qbittorrent/domain" = {};
}
