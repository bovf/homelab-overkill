# Prometheus stack app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./external-services.nix
    ./local-dns.nix
    ./wireguard-scrape.nix
    ./wireguard-monthly.nix
    ./uptime.nix
  ];
}
