{ ... }:

{
  imports = [
    ./persistent-volume-claim.nix
    ./deployment.nix
    ./service.nix
  ];
}
