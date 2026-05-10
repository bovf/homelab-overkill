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
        # The exporter emits its own `namespace` label (the PVC's actual
        # namespace), which Prometheus auto-renames to `exported_namespace`
        # because it collides with the scrape-target's namespace label
        # ("monitoring", where the exporter pod lives).
        # honorLabels alone wasn't picked up under kube-prometheus-stack 84.5,
        # so we explicitly relabel server-side: copy exported_namespace over
        # the bogus namespace, then drop exported_namespace.
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
