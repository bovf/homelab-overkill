# Kube-system namespace entrypoint
{ ... }:

{
  imports = [
    ./apps/traefik
    ./apps/node-feature-discovery
  ];
}
