{ config, ... }:

{
  workloads.localDnsRecords.uptime = {
    host = config.sops.placeholder."pangolin/resources/uptime/domain";
    ip   = "192.168.2.73";
  };
}
