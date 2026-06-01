{ ... }:

{
  workloads.uptimeMonitors.nzbget = {
    name      = "NZBGet";
    domainKey = "pangolin/resources/nzbget/domain";
    group     = "Media";
  };
}
