{ ... }:

{
  services.k3s.manifests.grafana-dashboard-storage.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-dashboard-storage";
      namespace = "monitoring";
      labels.grafana_dashboard = "1";
    };
    data."storage.json" = builtins.readFile ./dashboards/storage.json;
  };
}
