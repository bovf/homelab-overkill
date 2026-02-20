{ ... }:

{
  imports = [
    ./apps/ghost
  ];

  services.k3s.manifests.ghost-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "ghost";
  };
}
