{ ... }:

{
  services.k3s.manifests.attic-cache-service.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "attic-cache";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      type = "ClusterIP";
      # Tunnel-side exposure for Pangolin kernel-WG. Use service port 8090 to
      # avoid the existing qbittorrent externalIPs collision on 8080.
      externalIPs = [ "100.89.128.16" ];
      selector.app = "attic-cache";
      ports = [{
        name = "http";
        port = 8090;
        targetPort = "http";
        protocol = "TCP";
      }];
    };
  };
}
