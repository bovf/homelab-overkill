{ ... }:

{
  workloads.uptimeMonitors.argocd = {
    name      = "ArgoCD";
    domainKey = "pangolin/resources/argocd/domain";
    group     = "Dev";
  };
}
