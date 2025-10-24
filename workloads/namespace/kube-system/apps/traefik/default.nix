# Traefik app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./ingress.nix
    ./middleware.nix
    ./service.nix
  ];
}
