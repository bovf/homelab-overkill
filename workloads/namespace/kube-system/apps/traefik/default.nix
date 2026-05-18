{ ... }:

{
  imports = [
    ./helm.nix
    ./ingress.nix
    ./middleware.nix
    ./service.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./certificate.nix
  ];
}
