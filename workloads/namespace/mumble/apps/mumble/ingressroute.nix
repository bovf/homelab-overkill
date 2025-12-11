# apps/mumble/ingressroute.nix
{ ... }:

{
  services.k3s.manifests."mumble-ingressroute".content = {
    apiVersion = "traefik.containo.us/v1alpha1";
    kind = "IngressRouteUDP";
    metadata = {
      name = "mumble-ingressroute";
      namespace = "mumble";
    };
    spec = {
      entryPoints = [ "mumble-udp" ];  # Configure this in Traefik
      routes = [{
        match = "HostSNI(`*`)";  # Matches all UDP traffic
        services = [{
          name = "mumble-server-server";
          port = 64738;
        }];
      }];
    };
  };
}
