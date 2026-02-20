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
  };

  sops.secrets."pangolin/resources/pihole/domain" = {};
}
