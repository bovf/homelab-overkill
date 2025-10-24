{ ... }:

{
  services.k3s.manifests.traefik-dashboard-root-redirect.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "dashboard-root-redirect";
      namespace = "kube-system";
    };
    spec = {
      redirectRegex = {
        regex = "^https?://traefik\\.dobryops\\.com/?$";
        replacement = "https://traefik.dobryops.com/dashboard/";
        permanent = true;
      };
    };
  };

  services.k3s.manifests.traefik-dashboard-ingressroute.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "IngressRoute";
    metadata = {
      name = "traefik-dashboard";
      namespace = "kube-system";
      labels = {
        "app.kubernetes.io/name" = "traefik-dashboard";
        "app.kubernetes.io/instance" = "traefik";
      };
    };
    spec = {
      entryPoints = [ "web" "websecure" ];
      routes = [
        {
          match = "Host(`traefik.dobryops.com`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))";
          kind = "Rule";
          services = [
            {
              kind = "TraefikService";
              name = "api@internal";
            }
          ];
        }
        {
          match = "Host(`traefik.dobryops.com`) && Path(`/`)";
          kind = "Rule";
          middlewares = [
             { 
               name = "dashboard-root-redirect"; 
             }
          ];
          services = [
            { 
              kind = "TraefikService"; 
              name = "api@internal"; 
            }
          ];
        }
      ];
    };
  };
}
