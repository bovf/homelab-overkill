{ ... }:

{
  workloads.uptimeMonitors.radarr = {
    name      = "Radarr";
    domainKey = "pangolin/resources/radarr/domain";
    group     = "Media";
  };
}
