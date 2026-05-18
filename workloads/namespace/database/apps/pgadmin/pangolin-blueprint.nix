{ nodeName, ... }:

{
  workloads.pangolinResources.pgadmin = {
    name           = "pgAdmin";
    protocol       = "http";
    domainKey      = "pangolin/resources/pgadmin/domain";
    enabled        = false;
    ssoEnabled     = true;
    # Service port bumped to clear the tunnel-side port-80 collision.
    targetHostname = "pgadmin-pgadmin4.database.svc.cluster.local";
    targetMethod   = "http";
    targetPort     = 8088;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
    lanIP          = "192.168.2.13";
  };

  sops.secrets."pangolin/resources/pgadmin/domain" = {};
}
