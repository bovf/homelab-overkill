{ ... }:

# Pangolin path disabled — probe the cluster-internal Service.
{
  workloads.uptimeMonitors.pgadmin = {
    name  = "pgAdmin";
    url   = "http://pgadmin-extip.database.svc.cluster.local:8088";
    group = "Private";
  };
}
