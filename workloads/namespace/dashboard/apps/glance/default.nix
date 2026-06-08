{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./config.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
  ];
}
