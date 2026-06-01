{ ... }:

{
  imports = [
    ./helm.nix
    ./init-job.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
  ];
}
