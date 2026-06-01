# synapse-admin — web GUI for Synapse user/room administration
{ ... }:

{
  imports = [
    ./helm.nix
    ./configmap.nix
    ./middleware.nix
    ./pangolin-blueprint.nix
    ./local-dns.nix
    ./uptime.nix
  ];
}
