{ ... }:

{
  services.k3s.manifests.attic-cache-ingress.content = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "attic-cache";
      namespace = "proxy";
      annotations = {
        "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure";
      };
    };
    spec = {
      ingressClassName = "traefik";
      rules = [{
        host = "cache.dobryops.com";
        http.paths = [{
          path = "/";
          pathType = "Prefix";
          backend.service = {
            name = "attic-cache";
            port.name = "http";
          };
        }];
      }];
    };
  };
}
