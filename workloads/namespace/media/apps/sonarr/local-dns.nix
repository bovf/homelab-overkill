{ config, ... }:

{
  workloads.localDnsRecords.sonarr = {
    host = config.sops.placeholder."pangolin/resources/sonarr/domain";
    ip   = "192.168.2.45";
  };
}
