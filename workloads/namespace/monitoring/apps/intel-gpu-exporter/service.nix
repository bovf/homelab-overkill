{ ... }:

{
  services.k3s.manifests.intel-gpu-exporter-service.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "intel-gpu-exporter";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "intel-gpu-exporter";
    };
    spec = {
      type = "ClusterIP";
      selector."app.kubernetes.io/name" = "intel-gpu-exporter";
      ports = [{
        name = "metrics";
        port = 9100;
        targetPort = 9100;
        protocol = "TCP";
      }];
    };
  };

  services.k3s.manifests.intel-gpu-exporter-servicemonitor.content = {
    apiVersion = "monitoring.coreos.com/v1";
    kind = "ServiceMonitor";
    metadata = {
      name = "intel-gpu-exporter";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "intel-gpu-exporter";
    };
    spec = {
      selector.matchLabels."app.kubernetes.io/name" = "intel-gpu-exporter";
      endpoints = [{
        port = "metrics";
        interval = "15s";
        path = "/metrics";
      }];
    };
  };
}
