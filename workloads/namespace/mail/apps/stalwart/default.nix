# Stalwart mail server — single-pod SMTP/IMAPS with Brevo as outbound relay.
{ ... }:

{
  imports = [
    ./certificate.nix
    ./secret.nix
    ./helm.nix
    ./init-job.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
