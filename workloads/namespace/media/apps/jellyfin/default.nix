# Jellyfin app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./middleware.nix
    ./pangolin-blueprint.nix
  ];
}
