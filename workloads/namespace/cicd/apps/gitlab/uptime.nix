{...}: {
  workloads.uptimeMonitors.gitlab = {
    name = "GitLab";
    domainKey = "pangolin/resources/gitlab/domain";
    group = "Dev";
  };

  workloads.uptimeMonitors.gitlab_registry = {
    name = "GitLab Registry";
    domainKey = "pangolin/resources/registry/domain";
    path = "/v2/";
    group = "Dev";
    acceptedStatusCodes = ["200-299" "401"];
  };

  workloads.uptimeMonitors.gitlab_ssh = {
    name = "GitLab SSH";
    type = "port";
    host = "gitlab-gitlab-shell.cicd.svc.cluster.local";
    port = 22;
    group = "Private";
  };
}
