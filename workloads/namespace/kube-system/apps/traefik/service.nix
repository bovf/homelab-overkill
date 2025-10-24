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
      ports = [
        {
          name = "traefik";
          port = 9000;
          targetPort = 9000;
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
