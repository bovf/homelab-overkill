{ ... }:

{
  workloads.uptimeMonitors.grafana = {
    name      = "Grafana";
    domainKey = "pangolin/resources/grafana/domain";
    group     = "Ops";
  };

  workloads.uptimeMonitors.prometheus = {
    name      = "Prometheus";
    domainKey = "pangolin/resources/prometheus/domain";
    group     = "Ops";
  };

  workloads.uptimeMonitors.alertmanager = {
    name      = "Alertmanager";
    domainKey = "pangolin/resources/alertmanager/domain";
    group     = "Ops";
  };
}
