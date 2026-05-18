{ ... }:

{
  imports = [
    ./configmap.nix
    ./gitlab-secret.nix
    ./gitlab-init-job.nix
    ./loki-secret.nix
    ./loki-init-job.nix
    ./helm.nix
    ./job.nix
    ./middleware.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
  ];
}
