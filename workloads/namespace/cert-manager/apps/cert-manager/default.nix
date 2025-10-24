# Cert manager app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./cluster-issuer.nix
  ];
}
