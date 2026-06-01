{ config, ... }:

{
  workloads.localDnsRecords.cam = {
    host = config.sops.placeholder."pangolin/resources/cam/domain";
    ip   = "192.168.2.72";
  };
}
