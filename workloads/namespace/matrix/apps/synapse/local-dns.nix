{ config, ... }:

{
  workloads.localDnsRecords.matrix = {
    host = config.sops.placeholder."pangolin/resources/matrix/domain";
    ip   = "192.168.2.60";
  };
}
