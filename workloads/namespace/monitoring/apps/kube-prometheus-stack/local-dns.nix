{ config, ... }:

{
  workloads.localDnsRecords.grafana = {
    host = config.sops.placeholder."pangolin/resources/grafana/domain";
    ip   = "192.168.2.30";
  };

  workloads.localDnsRecords.prometheus = {
    host = config.sops.placeholder."pangolin/resources/prometheus/domain";
    ip   = "192.168.2.31";
  };

  workloads.localDnsRecords.alertmanager = {
    host = config.sops.placeholder."pangolin/resources/alertmanager/domain";
    ip   = "192.168.2.32";
  };
}
