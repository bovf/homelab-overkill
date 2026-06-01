{ ... }:

{
  workloads.uptimeMonitors.pgadmin = {
    name      = "pgAdmin";
    domainKey = "pangolin/resources/pgadmin/domain";
    group     = "Ops";
  };
}
