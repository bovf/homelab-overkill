{ config, ... }:

{
  workloads.localDnsRecords.whoami = {
    host = config.sops.placeholder."pangolin/resources/whoami/domain";
    ip   = "192.168.2.10";
  };
}
