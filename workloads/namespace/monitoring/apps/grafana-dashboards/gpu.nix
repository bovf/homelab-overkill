{ ... }:

{
  services.k3s.manifests.grafana-dashboard-intel-gpu.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-dashboard-intel-gpu";
      namespace = "monitoring";
      labels.grafana_dashboard = "1";
    };
    data."intel-gpu.json" = builtins.readFile ./dashboards/intel-gpu.json;
  };
}
