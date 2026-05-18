{ ... }:

{
  services.k3s.manifests.traefik-dashboard-svc.content = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "traefik-dashboard";
      namespace = "kube-system";
      labels = {
        "app.kubernetes.io/name" = "traefik-dashboard";
        "app.kubernetes.io/instance" = "traefik";
      };
    };
    spec = {
      type = "ClusterIP";
      externalIPs = [ "100.89.128.16" ];
      # Service port bumped from 8080 to avoid the tunnel-side
      # externalIPs collision with qbittorrent's :8080.
      ports = [
        {
          name = "traefik";
          port = 8081;
          targetPort = 8080;
          protocol = "TCP";
        }
      ];
      selector = {
        "app.kubernetes.io/name" = "traefik";
        "app.kubernetes.io/instance" = "traefik-kube-system";
      };
    };
  };
}
