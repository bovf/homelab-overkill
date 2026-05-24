{ ... }:

{
  services.k3s.manifests.grafana-dashboard-node-overview-mobile.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-dashboard-node-overview-mobile";
      namespace = "monitoring";
      labels.grafana_dashboard = "1";
    };
    data = {
      "node-overview-mobile-small.json"  = builtins.readFile ./dashboards/node-overview-mobile-small.json;
      "node-overview-mobile-medium.json" = builtins.readFile ./dashboards/node-overview-mobile-medium.json;
      "node-overview-mobile-large.json"  = builtins.readFile ./dashboards/node-overview-mobile-large.json;
    };
  };
}
