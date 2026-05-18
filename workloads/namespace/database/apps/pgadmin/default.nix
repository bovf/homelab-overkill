{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./external-services.nix
    ./local-dns.nix
  ];
}
