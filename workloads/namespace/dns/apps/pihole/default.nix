{...}: {
  imports = [
    ./helm.nix
    ./coredns-custom.nix
    ./secret.nix
    ./middleware.nix
    ./pangolin-blueprint.nix
    ./external-services.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
