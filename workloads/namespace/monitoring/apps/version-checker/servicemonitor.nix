{ ... }:

{
  # Custom ServiceMonitor for version-checker. The exporter emits its own
  # `namespace`/`pod`/`container` labels that describe the WATCHED workload,
  # but Prometheus's target labels overwrite them with the version-checker
  # pod's own location. Ungroundede via metric_relabel_configs server-side:
  # promote exported_* back to the canonical names, then drop the originals.
  services.k3s.manifests.version-checker-servicemonitor.content = {
    apiVersion = "monitoring.coreos.com/v1";
    kind = "ServiceMonitor";
    metadata = {
      # Don't use the bare name `version-checker` — that's the slot the chart
      # used when its own ServiceMonitor was enabled, and Helm's release-diff
      # will delete whatever sits there on the next upgrade.
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
