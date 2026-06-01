{ ... }:

{
  imports = [
    ./helm.nix
    ./config.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
