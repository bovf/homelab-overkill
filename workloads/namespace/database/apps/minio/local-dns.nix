{ config, ... }:

{
  workloads.localDnsRecords.minio = {
    host = config.sops.placeholder."pangolin/resources/minio/domain";
    ip   = "192.168.2.11";
  };

  workloads.localDnsRecords.minio_console = {
    host = config.sops.placeholder."pangolin/resources/minio_console/domain";
    ip   = "192.168.2.12";
  };
}
