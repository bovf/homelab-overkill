{ config, ... }:

{
  workloads.localDnsRecords.glance = {
    host = config.sops.placeholder."pangolin/resources/glance/domain";
    ip   = "192.168.2.76";
  };
}
