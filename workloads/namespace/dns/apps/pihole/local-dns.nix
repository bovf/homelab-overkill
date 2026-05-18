{ config, ... }:

{
  workloads.localDnsRecords.pihole = {
    host = config.sops.placeholder."pangolin/resources/pihole/domain";
    ip   = "192.168.2.15";
  };
}
