{ nodeName, ... }:

{
  workloads.pangolinResources.reactive_resume = {
    name           = "Reactive Resume";
    protocol       = "http";
    domainKey      = "pangolin/resources/reactive_resume/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/reactive_resume/domain" = {};
}
