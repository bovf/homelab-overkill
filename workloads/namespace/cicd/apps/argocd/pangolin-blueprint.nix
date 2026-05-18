{ nodeName, ... }:

{
  workloads.pangolinResources.argocd = {
    name           = "ArgoCD";
    protocol       = "http";
    domainKey      = "pangolin/resources/argocd/domain";
    enabled        = false;
    ssoEnabled     = true;
    # Service port bumped to clear the tunnel-side port-80 collision.
    targetHostname = "argocd-server.cicd.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8090;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.20";
  };

  sops.secrets."pangolin/resources/argocd/domain" = {};
}
