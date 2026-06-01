{ ... }:

# Pangolin path disabled — probe cluster-internal. Root `/` returns 403
# (host-header check); /admin/login is the safe always-200 endpoint.
{
  workloads.uptimeMonitors.pihole = {
    name  = "Pi-hole";
    url   = "http://pihole-web-extip.dns.svc.cluster.local:8089/admin/login";
    group = "Private";
  };
}
