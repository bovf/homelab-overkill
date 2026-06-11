{...}: {
  workloads.uptimeMonitors.glance = {
    name = "Glance Dashboard";
    domainKey = "pangolin/resources/glance/domain";
    group = "Dashboard";
  };
}
