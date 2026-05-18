{ config, ... }:

{
  workloads.localDnsRecords.bazarr = {
    host = config.sops.placeholder."pangolin/resources/bazarr/domain";
    ip   = "192.168.2.42";
  };
}
