{ ... }:

{
  services.k3s.manifests.squid-service.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "squid";
      namespace = "proxy";
      labels.app = "squid";
    };
    spec = {
      type = "LoadBalancer";
      loadBalancerIP = "192.0.2.10";
      ports = [{
        port = 3128;
        targetPort = 3128;
        protocol = "TCP";
        name = "proxy";
      }];
      selector.app = "squid";
    };
  };
}
