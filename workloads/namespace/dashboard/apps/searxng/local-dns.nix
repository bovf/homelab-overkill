{ config, ... }:

{
  workloads.localDnsRecords.search = {
    host = config.sops.placeholder."pangolin/resources/search/domain";
    ip   = "192.168.2.74";
  };
}
