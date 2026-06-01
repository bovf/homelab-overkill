{ ... }:

{
  workloads.uptimeMonitors.gitlab = {
    name      = "GitLab";
    domainKey = "pangolin/resources/gitlab/domain";
    group     = "Dev";
  };
}
