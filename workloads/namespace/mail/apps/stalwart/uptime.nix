{ ... }:

{
  workloads.uptimeMonitors.mail = {
    name      = "Mail";
    domainKey = "pangolin/resources/mailadmin/domain";
    group     = "Comms";
  };
}
