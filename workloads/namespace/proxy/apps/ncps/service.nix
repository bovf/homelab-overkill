{ ... }:

{
  services.k3s.manifests.ncps-service.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "ncps";
      namespace = "proxy";
      labels.app = "ncps";
    };
    spec = {
      type = "LoadBalancer";
      loadBalancerIP = "192.0.2.10";
      ports = [{
        port = 8501;
        targetPort = 8501;
        protocol = "TCP";
        name = "http";
      }];
      selector.app = "ncps";
    };
  };
}
