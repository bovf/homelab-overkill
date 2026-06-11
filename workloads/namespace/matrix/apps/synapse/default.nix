# Synapse Matrix homeserver app entrypoint
{...}: {
  imports = [
    ./helm.nix
    ./secret.nix
    ./middleware.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
