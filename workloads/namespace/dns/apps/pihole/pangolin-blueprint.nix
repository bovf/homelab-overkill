{ nodeName, ... }:

{
  workloads.pangolinResources.pihole = {
    name           = "Pi-hole";
    protocol       = "http";
    domainKey      = "pangolin/resources/pihole/domain";
    enabled        = false;
    ssoEnabled     = true;
    # webHttp was bumped to 8089 (was 80) for the same reason as pgadmin.
    # The pihole container binds to 8089 directly per the chart's webHttp setting.
    targetHostname = "pihole-web.dns.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8089;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.15";
  };

  sops.secrets."pangolin/resources/pihole/domain" = {};
}
