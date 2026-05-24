# ConfigMaps labelled grafana_datasource/grafana_dashboard are
# auto-imported by the kube-prometheus-stack grafana sidecar.
{ ... }:

{
  imports = [
    ./datasources.nix
    ./gpu.nix
    ./storage.nix
    ./traefik.nix
    ./networking.nix
    ./node-overview.nix
    ./node-overview-mobile.nix
    ./version-checker.nix
  ];
}
