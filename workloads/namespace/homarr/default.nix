# Homarr — single-page homepage / launcher for the whole stack.
{ ... }:

{
  imports = [
    ./apps/homarr
  ];

  services.k3s.manifests.homarr-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "homarr";
  };
}
