{ nodeName, ... }:

{
  workloads.pangolinResources.pihole = {
    name           = "Pi-hole";
    protocol       = "http";
    domainKey      = "pangolin/resources/pihole/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
    healthcheck = {
      hostname = "pihole-web.dns.svc.cluster.local";
      port     = 80;
      path     = "/admin/";
    };
  };

  sops.secrets."pangolin/resources/pihole/domain" = {};
}
