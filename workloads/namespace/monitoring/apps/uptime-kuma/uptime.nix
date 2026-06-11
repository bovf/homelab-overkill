{...}: {
  workloads.uptimeMonitors.uptime = {
    name = "Uptime Kuma";
    domainKey = "pangolin/resources/uptime/domain";
    group = "Ops";
  };
}
