{...}: {
  imports = [
    ./secret.nix
    ./helm.nix
    ./middleware.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];

  # Enable only after both encrypted IGDB values exist in SOPS.
  workloads.romm.igdb.enable = false;
}
