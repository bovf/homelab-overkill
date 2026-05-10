{ nodeName, ... }:

{
  workloads.pangolinResources.whoami = {
    name           = "whoami blog";
    protocol       = "http";
    domainKey      = "pangolin/resources/whoami/domain";
    enabled        = true;
    # Public personal blog — no SSO in front of it.
    ssoEnabled     = false;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/whoami/domain" = {};
}
