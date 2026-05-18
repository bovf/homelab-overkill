{ config, ... }:

{
  workloads.localDnsRecords.jellyfin = {
    host = config.sops.placeholder."pangolin/resources/jellyfin/domain";
    ip   = "192.168.2.40";
  };
}
