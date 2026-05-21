# coturn TURN server app entrypoint
{ ... }:

{
  imports = [
    ./certificate.nix
    ./helm.nix
    ./secret.nix
    ./pangolin-blueprint.nix
  ];
}
