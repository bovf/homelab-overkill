{ nodeName, ... }:

{
  workloads.pangolinResources.argocd = {
    name           = "ArgoCD";
    protocol       = "http";
    domainKey      = "pangolin/resources/argocd/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/argocd/domain" = {};
}
