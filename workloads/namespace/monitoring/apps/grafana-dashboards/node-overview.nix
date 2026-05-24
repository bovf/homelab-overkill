{ ... }:

{
  services.k3s.manifests.grafana-dashboard-node-overview.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-dashboard-node-overview";
      namespace = "monitoring";
      labels.grafana_dashboard = "1";
    };
    data."node-overview.json" = builtins.readFile ./dashboards/node-overview.json;
  };
}
