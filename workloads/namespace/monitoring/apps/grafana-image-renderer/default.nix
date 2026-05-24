# Headless-chromium image renderer for Grafana. Wired into Grafana via
# GF_RENDERING_SERVER_URL / GF_RENDERING_CALLBACK_URL in the
# kube-prometheus-stack helm values. Renders dashboards to PNG at a fixed
# desktop viewport so the responsive single-column stacking never triggers —
# the source of truth for iOS-widget URLs.
{ ... }:

{
  imports = [
    ./deployment.nix
    ./secret.nix
    ./service.nix
  ];
}
