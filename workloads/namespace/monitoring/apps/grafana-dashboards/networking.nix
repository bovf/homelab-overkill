{ ... }:

{
  services.k3s.manifests.grafana-dashboard-networking.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-dashboard-networking";
      namespace = "monitoring";
      labels.grafana_dashboard = "1";
    };
    data."networking.json" = builtins.readFile ./dashboards/networking.json;
  };
}
