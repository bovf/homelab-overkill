{ config, ... }:

{
  workloads.localDnsRecords.gitlab = {
    host = config.sops.placeholder."pangolin/resources/gitlab/domain";
    ip   = "192.168.2.21";
  };

  workloads.localDnsRecords.registry = {
    host = config.sops.placeholder."pangolin/resources/registry/domain";
    ip   = "192.168.2.22";
  };
}
