{ ... }:

{
  imports = [
    ./helm.nix
    ./settings.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
