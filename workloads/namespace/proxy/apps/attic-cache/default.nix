{ ... }:

{
  imports = [
    ./configmap.nix
    ./deployment.nix
    ./gc-cronjob.nix
    ./ingress.nix
    ./init-job.nix
    ./local-dns.nix
    ./pangolin-blueprint.nix
    ./persistent-volume-claim.nix
    ./secret.nix
    ./service.nix
  ];
}
