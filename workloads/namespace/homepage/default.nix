{ ... }:

{
  imports = [
    ./apps/homepage
  ];

  services.k3s.manifests.homepage-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "homepage";
  };
}
