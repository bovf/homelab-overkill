{ ... }:

{
  workloads.pangolinResources.home = {
    name           = "Homarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/home/domain";
    enabled        = true;
    # Public path stays SSO-gated; LAN path (192.168.2.71) bypasses Pangolin
    # entirely so the browser homepage loads instantly without re-auth.
    ssoEnabled     = true;
    targetHostname = "homarr.homarr.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8094;          # matches the Service's tunnel-IP port
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.71";
  };

  sops.secrets."pangolin/resources/home/domain" = {};
}
