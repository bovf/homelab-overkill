# Cert manager app entrypoint
{ ... }:

{
  imports = [
    ./helm.nix
    ./cluster-issuer.nix
    ./cluster-issuer-dns.nix
  ];
}
