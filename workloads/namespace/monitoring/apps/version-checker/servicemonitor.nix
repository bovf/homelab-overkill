{ ... }:

{
  # Promote exported_* labels back to canonical namespace/pod/container —
  # they describe the WATCHED workload, but the default target labels
  # overwrite them with the version-checker pod's own location.
  services.k3s.manifests.version-checker-servicemonitor.content = {
    apiVersion = "monitoring.coreos.com/v1";
    kind = "ServiceMonitor";
    metadata = {
      # Avoid the bare `version-checker` name — that slot was used by the
      # chart's own ServiceMonitor and gets deleted on Helm upgrade.
      name = "version-checker-monitor";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "version-checker";
    };
    spec = {
      selector.matchLabels."app.kubernetes.io/name" = "version-checker";
      namespaceSelector.matchNames = [ "monitoring" ];
      endpoints = [{
        port = "web";
        interval = "60s";
        path = "/metrics";
        scrapeTimeout = "30s";
        metricRelabelings = [
          {
            action = "replace";
            sourceLabels = [ "exported_namespace" ];
            regex = "(.+)";
            targetLabel = "namespace";
            replacement = "\$1";
          }
          {
            action = "replace";
            sourceLabels = [ "exported_pod" ];
            regex = "(.+)";
            targetLabel = "pod";
            replacement = "\$1";
          }
          {
            action = "replace";
            sourceLabels = [ "exported_container" ];
            regex = "(.+)";
            targetLabel = "container";
            replacement = "\$1";
          }
          {
            action = "labeldrop";
            regex = "exported_(namespace|pod|container)";
          }
        ];
      }];
    };
  };
}
