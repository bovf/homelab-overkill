{ nodeName, ... }:

{
  workloads.pangolinResources.synapse_admin = {
    name           = "Synapse Admin";
    protocol       = "http";
    domainKey      = "pangolin/resources/synapse_admin/domain";
    enabled        = true;
    # Admin tool — keep Pangolin SSO in front, on top of the Matrix
    # admin login it requires.
    ssoEnabled     = true;
    targetHostname = "synapse-admin.matrix.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 80;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.62";
  };

  sops.secrets."pangolin/resources/synapse_admin/domain" = {};
}
