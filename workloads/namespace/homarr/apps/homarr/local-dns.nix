{ config, ... }:

{
  workloads.localDnsRecords.home = {
    host = config.sops.placeholder."pangolin/resources/home/domain";
    ip   = "192.168.2.71";
  };
}
