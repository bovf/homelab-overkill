{ ... }:

{
  workloads.pangolinResources.speedtest = {
    name           = "Speedtest Tracker";
    protocol       = "http";
    domainKey      = "pangolin/resources/speedtest/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "speedtest-tracker.monitoring.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8099;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.75";
  };

  sops.secrets."pangolin/resources/speedtest/domain" = {};
}
