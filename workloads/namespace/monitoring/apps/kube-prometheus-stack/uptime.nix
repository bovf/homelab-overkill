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

  # Alertmanager's Pangolin resource is disabled — probe cluster-internal.
  workloads.uptimeMonitors.alertmanager = {
    name  = "Alertmanager";
    url   = "http://kube-prometheus-stack-alertmanager-extip.monitoring.svc.cluster.local:9093";
    group = "Private";
  };
}
