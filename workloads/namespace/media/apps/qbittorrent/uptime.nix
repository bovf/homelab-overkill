{ ... }:

{
  workloads.uptimeMonitors.qbittorrent = {
    name      = "qBittorrent";
    domainKey = "pangolin/resources/qbittorrent/domain";
    group     = "Media";
  };
}
