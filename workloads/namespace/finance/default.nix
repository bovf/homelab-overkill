# Personal finance namespace.
{ ... }:

{
  imports = [
    ./apps/ezbookkeeping
  ];

  services.k3s.manifests.finance-ns.content = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "finance";
  };
}
