{ ... }:

{
  # Basic auth for web interface (optional)
  services.k3s.manifests.pihole-auth-middleware.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "pihole-auth";
      namespace = "dns";
    };
    spec = {
      basicAuth = {
        secret = "pihole-auth-secret";
      };
    };
  };

  # Ingress route for Pi-hole web interface
  services.k3s.manifests.pihole-ingress.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "IngressRoute";
    metadata = {
      name = "pihole-web";
      namespace = "dns";
    };
    spec = {
      entryPoints = [ "websecure" "web" ];
      routes = [
        {
          match = "Host(`pihole.your-domain.local`)";
          kind = "Rule";
          services = [
            {
              name = "pihole";
              port = 80;
            }
          ];
        }
      ];
      tls = {
        certResolver = "letsencrypt";
      };
    };
  };
}
