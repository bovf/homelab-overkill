{ config, ... }:

{
  workloads.localDnsRecords.radarr = {
    host = config.sops.placeholder."pangolin/resources/radarr/domain";
    ip   = "192.168.2.44";
  };
}
