{ ... }:

{
  services.k3s.manifests.reactive-resume-ingress = {
    content = {
      apiVersion = "networking.k8s.io/v1";
      kind = "Ingress";
      metadata = {
        name = "reactive-resume";
        namespace = "resume";
        annotations = {
          "traefik.ingress.kubernetes.io/router.entrypoints" = "web,websecure";
          "traefik.ingress.kubernetes.io/router.middlewares" = "resume-reactive-resume-headers@kubernetescrd";
          "cert-manager.io/cluster-issuer" = "letsencrypt";
        };
      };
      spec = {
        ingressClassName = "traefik";
        rules = [
          {
            host = "resume.dobryops.com";
            http = {
              paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                  backend = {
                    service = {
                      name = "reactive-resume";
                      port = { number = 3000; };
                    };
                  };
                }
              ];
            };
          }
        ];
      };
    };
  };
}
