{ ... }:

{
  workloads.uptimeMonitors.pihole = {
    name      = "Pi-hole";
    domainKey = "pangolin/resources/pihole/domain";
    group     = "Ops";
  };
}
