{ ... }:

{
  workloads.uptimeMonitors.speedtest = {
    name      = "Speedtest";
    domainKey = "pangolin/resources/speedtest/domain";
    group     = "Dashboard";
  };
}
