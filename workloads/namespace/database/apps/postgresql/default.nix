{ ... }:

{
  imports = [
    ./statefulset.nix
    ./service.nix
    ./middleware.nix
    ./secret.nix
    ./gitlab-secret.nix
    ./gitlab-init-job.nix
  ];
}
