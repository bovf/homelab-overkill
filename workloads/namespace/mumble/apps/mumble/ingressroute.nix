{ ... }:

{
  # UDP for voice
  services.k3s.manifests.mumble-udp-route.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "IngressRouteUDP";
    metadata = {
      name = "mumble-udp";
      namespace = "mumble";
    };
    spec = {
      entryPoints = [ "mumble-udp" ];
      routes = [
        {
          services = [
            {
              name = "mumble-server";
              port = "voice";
            }
          ];
        }
      ];
    };
  };

  # TCP fallback / signaling
  services.k3s.manifests.mumble-tcp-route.content = {
    apiVersion = "traefik.io/v1alpha1";
    kind = "IngressRouteTCP";
    metadata = {
      name = "mumble-tcp";
      namespace = "mumble";
    };
    spec = {
      entryPoints = [ "mumble-tcp" ];
      routes = [
        {
          match = "HostSNI(`*`)";
          services = [
            {
              name = "mumble-server";
              port = "signaling";
            }
          ];
        }
      ];
    };
  };
}
