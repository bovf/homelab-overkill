{ config, ... }:

{
  workloads.localDnsRecords.homepage = {
    host = config.sops.placeholder."pangolin/resources/homepage/domain";
    ip   = "192.168.2.14";
  };
}
