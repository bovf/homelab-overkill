{ ... }:

{
  services.k3s.manifests.grafana-image-renderer-service.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "grafana-image-renderer";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "grafana-image-renderer";
    };
    spec = {
      type = "ClusterIP";
      selector."app.kubernetes.io/name" = "grafana-image-renderer";
      ports = [{
        name = "http";
        port = 8081;
        targetPort = 8081;
        protocol = "TCP";
      }];
    };
  };
}
