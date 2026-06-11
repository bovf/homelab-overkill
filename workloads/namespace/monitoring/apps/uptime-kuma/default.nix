{...}: {
  imports = [
    ./helm.nix
    ./middleware.nix
    ./init-job.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
