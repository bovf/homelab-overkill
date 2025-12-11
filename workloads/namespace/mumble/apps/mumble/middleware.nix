{ ... }:

{
  services.k3s.manifests."mumble-middleware".content = {
    apiVersion = "traefik.containo.us/v1alpha1";
    kind = "Middleware";
    metadata = {
      name = "mumble-middleware";
      namespace = "mumble";
    };
    spec = {
      stripPrefix = {
        prefixes = [ "/mumble" ];
      };
    };
  };
}
