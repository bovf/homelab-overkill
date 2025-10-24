# Media shared resources entrypoint
{ ... }:

{
  imports = [
    ./media-pvc-init.nix
    ./pvc.nix
  ];
}
