{config, ...}: {
  workloads.localDnsRecords.sparkyfitness = {
    host = config.sops.placeholder."pangolin/resources/sparkyfitness/domain";
    ip = "192.168.2.52";
  };
}
