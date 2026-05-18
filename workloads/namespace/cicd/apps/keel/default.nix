# Polls registries on a schedule and rolls Deployments when a watched
# tag's digest changes. Per-deployment opt-in via keel.sh/* annotations.
{ ... }:

{
  imports = [
    ./helm.nix
  ];
}
