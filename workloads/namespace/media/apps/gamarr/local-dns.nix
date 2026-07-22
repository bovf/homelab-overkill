{config, ...}: {
  workloads.localDnsRecords.gamarr = {
    host = config.sops.placeholder."pangolin/resources/gamarr/domain";
    ip = "192.168.2.49";
  };
}
