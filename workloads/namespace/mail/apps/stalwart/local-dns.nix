{ config, ... }:

{
  workloads.localDnsRecords.mailadmin = {
    host = config.sops.placeholder."pangolin/resources/mailadmin/domain";
    ip   = "192.168.2.70";
  };
}
