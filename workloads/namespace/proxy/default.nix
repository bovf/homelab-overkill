{ ... }:

{
  imports = [
    ./apps/attic-cache
    ./apps/ncps
    ./apps/squid
  ];

  services.k3s.manifests.proxy-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "proxy";
  };
}
