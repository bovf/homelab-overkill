{config, ...}: {
  workloads.localDnsRecords.romm = {
    host = config.sops.placeholder."pangolin/resources/romm/domain";
    ip = "192.168.2.53";
  };
}
