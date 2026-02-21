{ ... }:

{
  imports = [
    ./instances.nix
    ./secret.nix
    ./helm.nix
    ./rbac.nix
    ./cronjob.nix
  ];
}
