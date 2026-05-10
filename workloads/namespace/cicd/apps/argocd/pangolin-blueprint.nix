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
    healthcheck = {
      hostname = "argocd-server.cicd.svc.cluster.local";
      port     = 80;
      path     = "/healthz";
    };
  };

  sops.secrets."pangolin/resources/argocd/domain" = {};
}
