# Expose kwg tunnel health as Prometheus metrics. Pairs with the
# `ScrapeConfig` rendered in workloads/namespace/monitoring/apps/
# kube-prometheus-stack/wireguard-scrape.nix.
#
# Metrics published on :9586/metrics:
#   wireguard_latest_handshake_seconds{interface,peer}
#   wireguard_sent_bytes_total{interface,peer}
#   wireguard_received_bytes_total{interface,peer}
#
# The exporter needs CAP_NET_ADMIN to call `wg show`; the NixOS module
# wires that up automatically.
{ ... }:

{
  services.prometheus.exporters.wireguard = {
    enable        = true;
    port          = 9586;
    withRemoteIp  = true;
    # `single` = aggregate metrics across all wg interfaces; the alternative
    # `network` parses /etc/wireguard/*.conf and tries to label-rich every
    # peer. For one interface that's overkill.
    verbose       = false;
  };

  # Open the exporter port on engineer's LAN/cluster interface so the
  # in-cluster Prometheus pod can scrape it via the node IP.
  networking.firewall.allowedTCPPorts = [ 9586 ];
}
