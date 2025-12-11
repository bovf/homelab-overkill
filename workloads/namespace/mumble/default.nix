{ ... }:

{
  imports = [
    ./apps/mumble
  ];

  services.k3s.manifests.mumble-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "mumble";
  };
}
