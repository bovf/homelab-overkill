# Element Web client app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./configmap.nix
    ./middleware.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
  ];
}
