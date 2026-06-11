{...}: {
  imports = [
    ./helm.nix
    ./middleware.nix
    ./secret.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
