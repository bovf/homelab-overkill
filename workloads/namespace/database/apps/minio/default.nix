{ ... }:

{
  imports = [
    ./configmap.nix
    ./gitlab-secret.nix
    ./gitlab-init-job.nix
    ./helm.nix
    ./job.nix
    ./middleware.nix
    ./reactive-resume-secret.nix
    ./reactive-resume-init-job.nix
    ./reactive-resume-configmap.nix
    ./secret.nix
  ];
}
