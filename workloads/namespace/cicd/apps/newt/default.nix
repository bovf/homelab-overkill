{ ... }:

{
  imports = [
    ./secret.nix
    ./helm.nix
    ./rbac.nix
    ./cronjob.nix
  ];
}
