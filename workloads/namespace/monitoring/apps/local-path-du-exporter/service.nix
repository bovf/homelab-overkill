{ ... }:

{
  services.k3s.manifests.local-path-du-exporter-service.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "local-path-du-exporter";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "local-path-du-exporter";
    };
    spec = {
      type = "ClusterIP";
      selector."app.kubernetes.io/name" = "local-path-du-exporter";
      ports = [{
        name = "metrics";
        port = 9101;
        targetPort = 9101;
        protocol = "TCP";
      }];
    };
  };

  services.k3s.manifests.local-path-du-exporter-servicemonitor.content = {
    apiVersion = "monitoring.coreos.com/v1";
    kind = "ServiceMonitor";
    metadata = {
      name = "local-path-du-exporter";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "local-path-du-exporter";
    };
    spec = {
      selector.matchLabels."app.kubernetes.io/name" = "local-path-du-exporter";
      endpoints = [{
        port = "metrics";
        interval = "60s";
        path = "/metrics";
        scrapeTimeout = "30s";
        # Exporter's `namespace` label (the PVC's namespace) gets renamed
        # to `exported_namespace` by Prometheus — promote it back.
        metricRelabelings = [
          {
            action = "replace";
            sourceLabels = [ "exported_namespace" ];
            targetLabel = "namespace";
          }
          {
            action = "labeldrop";
            regex = "exported_namespace";
          }
        ];
      }];
    };
  };
}
