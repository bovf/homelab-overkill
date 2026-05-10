# Jetstack version-checker — exposes Prometheus metrics about whether each
# running container's image tag is the latest available upstream.
{ ... }:

{
  imports = [
    ./helm.nix
    ./servicemonitor.nix
    ./prometheusrule.nix
  ];
}
