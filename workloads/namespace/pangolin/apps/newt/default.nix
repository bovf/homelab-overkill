# Newt app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./secret.nix
    ./instances.nix
    ./blueprint.nix
    ./extra-resources.nix
  ];
}
