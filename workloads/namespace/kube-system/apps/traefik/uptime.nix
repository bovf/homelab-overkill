{...}: {
  workloads.uptimeMonitors.traefik_dashboard = {
    name = "Traefik Dashboard";
    domainKey = "pangolin/resources/traefik_dashboard/domain";
    group = "Ops";
  };
}
