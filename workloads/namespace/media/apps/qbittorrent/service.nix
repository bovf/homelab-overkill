{ ... }:

{
  services.k3s.manifests.qbittorrent-bittorrent-service.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "qbittorrent-bittorrent";
      namespace = "media";
    };
    spec = {
      type = "LoadBalancer";
      selector = {
        "app.kubernetes.io/name" = "qbittorrent-vpn";
      };
      ports = [
        {
          name = "bittorrent-tcp";
          port = 6881;
          targetPort = 6881;
          protocol = "TCP";
        }
        {
          name = "bittorrent-udp";
          port = 6881;
          targetPort = 6881;
          protocol = "UDP";
        }
      ];
    };
  };
}
