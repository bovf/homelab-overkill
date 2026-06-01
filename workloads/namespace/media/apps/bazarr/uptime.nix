{ ... }:

{
  workloads.uptimeMonitors.bazarr = {
    name      = "Bazarr";
    domainKey = "pangolin/resources/bazarr/domain";
    group     = "Media";
  };
}
