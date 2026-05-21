{ config, ... }:

{
  workloads.localDnsRecords.synapse_admin = {
    host = config.sops.placeholder."pangolin/resources/synapse_admin/domain";
    ip   = "192.168.2.62";
  };
}
