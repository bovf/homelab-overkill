{ nodeName, ... }:

{
  workloads.pangolinResources.bazarr = {
    name           = "Bazarr";
    protocol       = "http";
    domainKey      = "pangolin/resources/bazarr/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/bazarr/domain" = {};
}
