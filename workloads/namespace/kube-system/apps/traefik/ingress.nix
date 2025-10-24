{ ... }:

{
  services.k3s.manifests.traefik-dashboard-ingress.content = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "traefik-dashboard";
      namespace = "kube-system";
      annotations = {
        "kubernetes.io/ingress.class" = "traefik";
        "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure";
      };
    };
    spec = {
      rules = [
        {
          host = "traefik.dobryops.com";
          http = {
            paths = [
              {
                path = "/dashboard";
                pathType = "Prefix";
                backend = {
                  service = {
                    name = "traefik-dashboard";
                    port = { number = 9000; };
                  };
                };
              }
              {
                path = "/api";
                pathType = "Prefix";
                backend = {
                  service = {
                    name = "traefik-dashboard";
                    port = { number = 9000; };
                  };
                };
              }
            ];
          };
        }
      ];
    };
  };
}
