{ ... }:

{
  services.k3s.manifests.grafana-dashboard-traefik.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-dashboard-traefik";
      namespace = "monitoring";
      labels.grafana_dashboard = "1";
    };
    data."traefik.json" = builtins.replaceStrings
      [ "\${DS_PROMETHEUS}" ]
      [ "Prometheus" ]
      (builtins.readFile ./dashboards/traefik.json);
  };
}
