{...}: {
  imports = [
    ./statefulset.nix
    ./service.nix
    ./middleware.nix
    ./secret.nix
    ./gitlab-secret.nix
    ./gitlab-init-job.nix
    ./ezbookkeeping-secret.nix
    ./ezbookkeeping-init-job.nix
    ./synapse-secret.nix
    ./synapse-init-job.nix
    ./sparkyfitness-secret.nix
    ./sparkyfitness-init-job.nix
    ./romm-secret.nix
    ./romm-init-job.nix
  ];
}
