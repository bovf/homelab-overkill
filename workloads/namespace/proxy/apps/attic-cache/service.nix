{...}: {
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
      # Tunnel-side exposure for Pangolin kernel-WG. Keep this unique across
      # all Services using externalIPs = 100.89.128.16; 8090 is ArgoCD.
      externalIPs = ["100.89.128.16"];
      selector.app = "attic-cache";
      ports = [
        {
          name = "http";
          port = 8102;
          targetPort = "http";
          protocol = "TCP";
        }
      ];
    };
  };
}
