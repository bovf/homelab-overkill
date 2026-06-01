{ ... }:

{
  workloads.uptimeMonitors.sonarr = {
    name      = "Sonarr";
    domainKey = "pangolin/resources/sonarr/domain";
    group     = "Media";
  };
}
