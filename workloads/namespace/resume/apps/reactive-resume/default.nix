{ ... }:

{
  imports = [
    ./middleware.nix
    ./configmap.nix
    ./deployment.nix
    ./ingress.nix
    ./secret.nix
    ./service.nix
  ];
}
