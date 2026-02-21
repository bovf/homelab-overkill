# qBittorrent app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./secret.nix
    ./service.nix
    ./pangolin-blueprint.nix
  ];
}
