{ config, ... }:

{
  workloads.localDnsRecords.ms_researcher_kb = {
    host = config.sops.placeholder."pangolin/resources/ms_kb/domain";
    ip   = "192.168.2.77";
  };
}
