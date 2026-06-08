{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./settings.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
