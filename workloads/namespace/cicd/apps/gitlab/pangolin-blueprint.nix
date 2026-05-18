{ ... }:

{
  workloads.pangolinResources.gitlab = {
    name           = "GitLab";
    protocol       = "http";
    domainKey      = "pangolin/resources/gitlab/domain";
    enabled        = true;
    ssoEnabled     = false;
    targetHostname = "gitlab-webservice-default.cicd.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8181;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.21";
  };

  workloads.pangolinResources.registry = {
    name           = "Container Registry";
    protocol       = "http";
    domainKey      = "pangolin/resources/registry/domain";
    enabled        = true;
    ssoEnabled     = false;
    targetHostname = "gitlab-registry.cicd.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 5000;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.22";
  };

  workloads.pangolinResources.gitlab_ssh = {
    name           = "GitLab SSH";
    protocol       = "tcp";
    proxyPortKey   = "pangolin/resources/gitlab_ssh/port";
    enabled        = true;
    # An arbitrary tunnel-side port — kept distinct from the user-facing
    # proxy-port (which lives in sops) so the port number isn't leaked
    # in the nix store / git. gitlab-shell-extip's Service catches
    # 100.89.128.16:22022 and DNATs to the pod.
    targetHostname = "gitlab-gitlab-shell.cicd.svc.cluster.local";
    targetPort     = 22022;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
  };

  sops.secrets."pangolin/resources/gitlab/domain"     = {};
  sops.secrets."pangolin/resources/registry/domain"   = {};
  sops.secrets."pangolin/resources/gitlab_ssh/port"   = {};
}
