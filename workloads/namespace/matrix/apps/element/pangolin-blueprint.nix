{ nodeName, ... }:

{
  workloads.pangolinResources.element = {
    name           = "Element Web";
    protocol       = "http";
    domainKey      = "pangolin/resources/element/domain";
    enabled        = true;
    # Element is a static SPA — the Matrix login inside it is the auth gate.
    ssoEnabled     = false;
    targetHostname = "element.matrix.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8091;          # matches the Service's tunnel-IP port
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.61";
  };

  sops.secrets."pangolin/resources/element/domain" = {};
}
