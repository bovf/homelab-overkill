{ config, ... }:

{
  workloads.localDnsRecords.traefik_dashboard = {
    host = config.sops.placeholder."pangolin/resources/traefik_dashboard/domain";
    ip   = "192.168.2.16";
  };
}
