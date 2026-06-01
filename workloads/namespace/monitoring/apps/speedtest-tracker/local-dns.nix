{ config, ... }:

{
  workloads.localDnsRecords.speedtest = {
    host = config.sops.placeholder."pangolin/resources/speedtest/domain";
    ip   = "192.168.2.75";
  };
}
