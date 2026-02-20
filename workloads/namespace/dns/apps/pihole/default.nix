{ ... }:

{
  imports = [
    ./helm.nix
    ./secret.nix
    ./middleware.nix
    ./pangolin-blueprint.nix
  ];
}
