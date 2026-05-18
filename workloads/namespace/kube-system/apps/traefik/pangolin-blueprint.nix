{ ... }:

{
  workloads.pangolinResources.traefik_dashboard = {
    name           = "Traefik Dashboard";
    protocol       = "http";
    domainKey      = "pangolin/resources/traefik_dashboard/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik-dashboard.kube-system.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8081;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.16";
  };

  sops.secrets."pangolin/resources/traefik_dashboard/domain" = {};
}
