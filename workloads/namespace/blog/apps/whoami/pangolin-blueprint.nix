{ nodeName, ... }:

{
  workloads.pangolinResources.whoami = {
    name           = "whoami blog";
    protocol       = "http";
    domainKey      = "pangolin/resources/whoami/domain";
    enabled        = true;
    # Public personal blog — no SSO in front of it.
    ssoEnabled     = false;
    targetHostname = "whoami.blog.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 80;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.10";
  };

  sops.secrets."pangolin/resources/whoami/domain" = {};
}
