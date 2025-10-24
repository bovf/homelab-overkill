# qBittorrent app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./secret.nix
  ];
}
