{ ... }:

{
  workloads.uptimeMonitors.jellyfin = {
    name      = "Jellyfin";
    domainKey = "pangolin/resources/jellyfin/domain";
    group     = "Media";
  };
}
