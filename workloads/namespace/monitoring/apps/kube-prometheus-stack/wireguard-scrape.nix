# Prometheus scrape job for the host-side wireguard exporter on engineer.
# kube-prometheus-stack's prometheusSpec has
# scrapeConfigSelectorNilUsesHelmValues=false, so it auto-discovers
# ScrapeConfig CRDs across all namespaces.
#
# Rendered as a sops template (not services.k3s.manifests) because the
# target is engineer's LAN IP, which lives encrypted in SOPS
# (nodes/engineer/ip) — the repo is public. node-exporter, the kubelet,
# and wireguard all reach Prometheus via the in-cluster path → node LAN IP.
{config, ...}: {
  sops.secrets."nodes/engineer/ip" = {};

  sops.templates."wireguard-scrape.yaml" = {
    content = ''
      apiVersion: monitoring.coreos.com/v1alpha1
      kind: ScrapeConfig
      metadata:
        name: wireguard-engineer
        namespace: monitoring
        labels:
          release: kube-prometheus-stack
      spec:
        jobName: wireguard-engineer
        scrapeInterval: 30s
        staticConfigs:
          - targets:
              - "${config.sops.placeholder."nodes/engineer/ip"}:9586"
            labels:
              instance: engineer
              node: engineer
    '';
    path = "/var/lib/rancher/k3s/server/manifests/wireguard-scrape.yaml";
    owner = "root";
    group = "root";
    mode = "0600";
  };
}
