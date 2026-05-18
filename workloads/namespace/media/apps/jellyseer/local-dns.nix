{ config, ... }:

{
  workloads.localDnsRecords.jellyseerr = {
    host = config.sops.placeholder."pangolin/resources/jellyseerr/domain";
    ip   = "192.168.2.41";
  };
}
