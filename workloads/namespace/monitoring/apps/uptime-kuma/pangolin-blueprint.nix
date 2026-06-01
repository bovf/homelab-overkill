{ ... }:

{
  workloads.pangolinResources.uptime = {
    name           = "Uptime Kuma";
    protocol       = "http";
    domainKey      = "pangolin/resources/uptime/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "uptime-kuma.monitoring.svc.cluster.local";
    targetMethod   = "http";
    # Tunnel-IP-side port the kube-proxy externalIPs rule binds.
    targetPort     = 8097;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.73";
  };

  sops.secrets."pangolin/resources/uptime/domain" = {};
}
