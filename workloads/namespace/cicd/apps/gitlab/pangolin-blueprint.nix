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
    healthcheck = {
      hostname = "gitlab-webservice-default.cicd.svc.cluster.local";
      port     = 8181;
      path     = "/-/health";
    };
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
    healthcheck = {
      # The Distribution v2 registry's own endpoints (e.g. /v2/) always
      # return 401 when anonymous reads are disabled — Pangolin would mark
      # them unhealthy. Proxy the registry's liveness through GitLab's
      # webservice instead: same Helm release, same pod lifecycle, real
      # 200 OK. If GitLab is up the bundled registry is up too.
      hostname = "gitlab-webservice-default.cicd.svc.cluster.local";
      port     = 8181;
      path     = "/-/health";
    };
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
