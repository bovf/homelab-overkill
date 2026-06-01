{ ... }:

{
  imports = [
    ./helm.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
  ];
}
