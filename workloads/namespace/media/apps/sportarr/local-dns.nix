{ config, ... }:

{
  workloads.localDnsRecords.sportarr = {
    host = config.sops.placeholder."pangolin/resources/sportarr/domain";
    ip   = "192.168.2.46";
  };
}
