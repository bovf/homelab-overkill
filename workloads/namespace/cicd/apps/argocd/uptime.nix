{ ... }:

# Pangolin path disabled — probe the cluster-internal Service.
{
  workloads.uptimeMonitors.argocd = {
    name  = "ArgoCD";
    url   = "http://argocd-server.cicd.svc.cluster.local:8090";
    group = "Private";
  };
}
