# Newt app entrypoint
{ ... }:

{
  imports = [
    # Import app specific definitions
    ./helm.nix
    ./secret.nix
  ];
}
