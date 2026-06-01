{ ... }:

{
  workloads.uptimeMonitors.prowlarr = {
    name      = "Prowlarr";
    domainKey = "pangolin/resources/prowlarr/domain";
    group     = "Media";
  };
}
