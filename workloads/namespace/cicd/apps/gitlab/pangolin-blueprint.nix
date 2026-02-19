{ nodeName, ... }:

{
  workloads.pangolinResources.gitlab = {
    name           = "GitLab";
    protocol       = "http";
    domainKey      = "pangolin/resources/gitlab/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/gitlab/domain" = {};
}
