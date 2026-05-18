{ config, ... }:

{
  workloads.localDnsRecords.argocd = {
    host = config.sops.placeholder."pangolin/resources/argocd/domain";
    ip   = "192.168.2.20";
  };
}
