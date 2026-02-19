{ nodeName, ... }:

{
  workloads.pangolinResources.pgadmin = {
    name           = "pgAdmin";
    protocol       = "http";
    domainKey      = "pangolin/resources/pgadmin/domain";
    enabled        = false;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/pgadmin/domain" = {};
}
