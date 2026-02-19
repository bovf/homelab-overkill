{ nodeName, ... }:

{
  workloads.pangolinResources.qbittorrent = {
    name           = "qBittorrent VPN";
    protocol       = "http";
    domainKey      = "pangolin/resources/qbittorrent/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/qbittorrent/domain" = {};
}
