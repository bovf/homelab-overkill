{ ... }:

# Pangolin path disabled. Cluster-internal pihole-web-extip returns 403
# on /admin (host-header check); easier to ride the public domain which
# CoreDNS resolves through pi-hole's own FTLCONF_dns_hosts to the
# 192.168.2.x LAN IP → traefik → pi-hole. Never leaves the LAN.
{
  workloads.uptimeMonitors.pihole = {
    name      = "Pi-hole";
    domainKey = "pangolin/resources/pihole/domain";
    path      = "/admin/login";
    group     = "Private";
  };
}
