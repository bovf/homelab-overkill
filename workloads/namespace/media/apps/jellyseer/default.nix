# Jellyseer app entrypoint
{ ... }:

{
  imports = [
    # Import app specific definitions
    ./helm.nix
    ./middleware.nix
  ];
}
