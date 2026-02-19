{ ... }:

{
  imports = [
    ./apps/pihole
  ];

  services.k3s.manifests.dns-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "dns";
  };
}
