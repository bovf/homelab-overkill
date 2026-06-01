{ ... }:

{
  workloads.uptimeMonitors.jellyseerr = {
    name      = "Jellyseerr";
    domainKey = "pangolin/resources/jellyseerr/domain";
    group     = "Media";
  };
}
