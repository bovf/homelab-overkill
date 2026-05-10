{ ... }:

{
  services.k3s.manifests.grafana-loki-datasource.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "grafana-loki-datasource";
      namespace = "monitoring";
      labels.grafana_datasource = "1";
    };
    data."loki-datasource.yaml" = builtins.toJSON {
      apiVersion = 1;
      datasources = [{
        name = "Loki";
        type = "loki";
        uid = "loki";
        url = "http://loki.monitoring.svc.cluster.local:3100";
        access = "proxy";
        isDefault = false;
        editable = false;
        jsonData = {
          maxLines = 1000;
          timeout = 60;
        };
      }];
    };
  };
}
