{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./external-services.nix
    ./lan-shell-service.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
