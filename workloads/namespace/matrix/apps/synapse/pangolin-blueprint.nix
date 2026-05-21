{ nodeName, ... }:

{
  workloads.pangolinResources.matrix = {
    name           = "Matrix (Synapse)";
    protocol       = "http";
    domainKey      = "pangolin/resources/matrix/domain";
    enabled        = true;
    # Matrix clients can't complete a Pangolin SSO browser flow — the
    # homeserver's own login is the auth gate.
    ssoEnabled     = false;
    targetHostname = "synapse.matrix.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8008;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.60";
  };

  sops.secrets."pangolin/resources/matrix/domain" = {};
}
