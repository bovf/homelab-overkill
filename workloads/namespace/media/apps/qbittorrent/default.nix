# qBittorrent app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./secret.nix
    ./vpn-secret.nix
    ./pangolin-blueprint.nix
  ];
}
