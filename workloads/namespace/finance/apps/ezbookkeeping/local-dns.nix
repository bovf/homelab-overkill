{ config, ... }:

{
  workloads.localDnsRecords.ezbookkeeping = {
    host = config.sops.placeholder."pangolin/resources/ezbookkeeping/domain";
    ip   = "192.168.2.50";
  };
}
