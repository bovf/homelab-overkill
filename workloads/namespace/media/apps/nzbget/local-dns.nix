{ config, ... }:

{
  workloads.localDnsRecords.nzbget = {
    host = config.sops.placeholder."pangolin/resources/nzbget/domain";
    ip   = "192.168.2.47";
  };
}
