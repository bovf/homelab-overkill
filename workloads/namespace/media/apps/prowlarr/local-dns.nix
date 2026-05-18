{ config, ... }:

{
  workloads.localDnsRecords.prowlarr = {
    host = config.sops.placeholder."pangolin/resources/prowlarr/domain";
    ip   = "192.168.2.43";
  };
}
