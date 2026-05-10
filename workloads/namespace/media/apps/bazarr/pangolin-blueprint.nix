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
    healthcheck = {
      hostname = "bazarr.media.svc.cluster.local";
      port     = 6767;
      path     = "/ping";
    };
  };

  sops.secrets."pangolin/resources/bazarr/domain" = {};
}
