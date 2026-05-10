{ ... }:

{
  services.k3s.manifests.grafana-dashboard-version-checker.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-dashboard-version-checker";
      namespace = "monitoring";
      labels.grafana_dashboard = "1";
    };
    data."version-checker.json" = builtins.readFile ./dashboards/version-checker.json;
  };
}
