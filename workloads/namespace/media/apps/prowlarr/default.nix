# Prowlarr app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
  ];
}
