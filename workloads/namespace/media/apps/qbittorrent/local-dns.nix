{ config, ... }:

{
  workloads.localDnsRecords.qbittorrent = {
    host = config.sops.placeholder."pangolin/resources/qbittorrent/domain";
    ip   = "192.168.2.48";
  };
}
