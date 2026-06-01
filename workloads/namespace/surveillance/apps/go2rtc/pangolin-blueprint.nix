{ ... }:

{
  workloads.pangolinResources.cam = {
    name           = "Home Camera";
    protocol       = "http";
    domainKey      = "pangolin/resources/cam/domain";
    # Resource off by default — the cam is a hot mic + webcam, so the
    # public Pangolin path stays disabled until manually enabled in the
    # Pangolin UI. SSO stays on so when it IS enabled, it's still gated.
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "go2rtc.surveillance.svc.cluster.local";
    targetMethod   = "http";
    # viaKernelWg=true rewrites targetHostname to the kwg tunnel IP
    # (100.89.128.16) but leaves targetPort as-is — so this must match the
    # Service's externalIP port (8095), NOT go2rtc's container port (1984).
    targetPort     = 8095;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.72";
  };

  sops.secrets."pangolin/resources/cam/domain" = {};
}
