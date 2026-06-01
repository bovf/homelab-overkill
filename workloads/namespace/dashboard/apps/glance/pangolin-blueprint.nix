{ ... }:

{
  workloads.pangolinResources.glance = {
    name           = "Glance Dashboard";
    protocol       = "http";
    domainKey      = "pangolin/resources/glance/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "glance.dashboard.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8100;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.76";
  };

  sops.secrets."pangolin/resources/glance/domain" = {};
}
