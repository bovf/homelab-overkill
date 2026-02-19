{ ... }:

{
  imports = [
    ./helm.nix
    ./secret.nix
    # ./ingressroute.nix
    ./certificate.nix
  ];
}
