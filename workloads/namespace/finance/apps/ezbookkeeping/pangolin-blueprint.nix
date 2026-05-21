{ nodeName, ... }:

{
  workloads.pangolinResources.ezbookkeeping = {
    name           = "ezBookkeeping";
    protocol       = "http";
    domainKey      = "pangolin/resources/ezbookkeeping/domain";
    enabled        = true;
    # Financial data — keep Pangolin SSO in front of the app's own login.
    ssoEnabled     = true;
    targetHostname = "ezbookkeeping.finance.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8080;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.50";
  };

  sops.secrets."pangolin/resources/ezbookkeeping/domain" = {};
}
