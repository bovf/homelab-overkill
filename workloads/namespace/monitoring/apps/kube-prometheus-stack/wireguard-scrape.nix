# Prometheus scrape job for the host-side wireguard exporter on engineer.
# kube-prometheus-stack's prometheusSpec has
# scrapeConfigSelectorNilUsesHelmValues=false, so it auto-discovers
# ScrapeConfig CRDs across all namespaces.
#
# Engineer's LAN IP is 192.0.2.10 (from flake.nix nodes.engineer.ip);
# node-exporter, the kubelet, and now wireguard all reach Prometheus via
# the in-cluster path → node LAN IP.
{ ... }:

{
  services.k3s.manifests.wireguard-scrape.content = {
    apiVersion = "monitoring.coreos.com/v1alpha1";
    kind       = "ScrapeConfig";
    metadata = {
      name      = "wireguard-engineer";
      namespace = "monitoring";
      labels.release = "kube-prometheus-stack";
    };
    spec = {
      jobName        = "wireguard-engineer";
      scrapeInterval = "30s";
      staticConfigs = [
        {
          targets = [ "192.0.2.10:9586" ];
          labels = {
            instance = "engineer";
            node     = "engineer";
          };
        }
      ];
    };
  };
}
