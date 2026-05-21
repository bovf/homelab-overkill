{ nodeName, ... }:

{
  # Hyphen, not underscore: the lan-services lib derives a Kubernetes
  # Service name (`<key>-lan`) from this key, and `_` is illegal there.
  workloads.pangolinResources."synapse-admin" = {
    name           = "Synapse Admin";
    protocol       = "http";
    domainKey      = "pangolin/resources/synapse_admin/domain";
    enabled        = true;
    # Admin tool — keep Pangolin SSO in front, on top of the Matrix
    # admin login it requires.
    ssoEnabled     = true;
    targetHostname = "synapse-admin.matrix.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8092;          # matches the Service's tunnel-IP port
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.62";
  };

  sops.secrets."pangolin/resources/synapse_admin/domain" = {};
}
