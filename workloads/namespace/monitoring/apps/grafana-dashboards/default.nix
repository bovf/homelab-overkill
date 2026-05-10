# Declarative Grafana datasources + curated dashboards.
#
# Pattern: ConfigMaps labelled `grafana_datasource: "1"` or `grafana_dashboard: "1"`
# are auto-imported by the kube-prometheus-stack Grafana sidecar.
#
# Datasources are declared inline. Dashboards are JSON files vendored under
# ./dashboards/ and read with builtins.readFile.
{ ... }:

{
  imports = [
    ./datasources.nix
    ./gpu.nix
    ./storage.nix
    ./traefik.nix
    ./networking.nix
    ./version-checker.nix
  ];
}
