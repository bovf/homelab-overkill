{ ... }:

# Pangolin path disabled — probe the cluster-internal Service.
{
  workloads.uptimeMonitors.pihole = {
    name  = "Pi-hole";
    url   = "http://pihole-web-extip.dns.svc.cluster.local:8089";
    group = "Private";
  };
}
