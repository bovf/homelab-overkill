{ config, ... }:

{
  workloads.localDnsRecords.element = {
    host = config.sops.placeholder."pangolin/resources/element/domain";
    ip   = "192.168.2.61";
  };
}
