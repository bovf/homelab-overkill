{ nodeName, ... }:

{
  workloads.pangolinResources.gitlab = {
    name           = "GitLab";
    protocol       = "http";
    domainKey      = "pangolin/resources/gitlab/domain";
    enabled        = true;
    ssoEnabled     = false;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  workloads.pangolinResources.registry = {
    name           = "Container Registry";
    protocol       = "http";
    domainKey      = "pangolin/resources/registry/domain";
    enabled        = true;
    ssoEnabled     = false;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  workloads.pangolinResources.gitlab_ssh = {
    name           = "GitLab SSH";
    protocol       = "tcp";
    proxyPortKey   = "pangolin/resources/gitlab_ssh/port";
    enabled        = true;
    targetHostname = "gitlab-gitlab-shell.cicd.svc.cluster.local";
    targetPort     = 22;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/gitlab/domain" = {};
  sops.secrets."pangolin/resources/registry/domain" = {};
  sops.secrets."pangolin/resources/gitlab_ssh/port" = {};
}
