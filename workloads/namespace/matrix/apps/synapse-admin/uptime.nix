{ ... }:

{
  workloads.uptimeMonitors.synapse_admin = {
    name      = "Synapse Admin";
    domainKey = "pangolin/resources/synapse_admin/domain";
    group     = "Comms";
  };
}
