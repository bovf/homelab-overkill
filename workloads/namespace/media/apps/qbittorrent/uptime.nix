{ ... }:

# Pangolin path disabled — probe the cluster-internal Service.
{
  workloads.uptimeMonitors.qbittorrent = {
    name  = "qBittorrent";
    url   = "http://qbittorrent.media.svc.cluster.local:8080";
    group = "Private";
  };
}
