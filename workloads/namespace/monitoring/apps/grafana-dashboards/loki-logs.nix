{...}: {
  services.k3s.manifests.grafana-dashboard-loki-logs.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-dashboard-loki-logs";
      namespace = "monitoring";
      labels.grafana_dashboard = "1";
    };
    data."loki-logs-app.json" = builtins.readFile ./dashboards/loki-logs.json;
  };
}
