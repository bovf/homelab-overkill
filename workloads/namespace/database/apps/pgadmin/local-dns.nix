{ config, ... }:

{
  workloads.localDnsRecords.pgadmin = {
    host = config.sops.placeholder."pangolin/resources/pgadmin/domain";
    ip   = "192.168.2.13";
  };
}
