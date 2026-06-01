{ ... }:

{
  workloads.uptimeMonitors.minio = {
    name      = "MinIO";
    domainKey = "pangolin/resources/minio_console/domain";
    group     = "Ops";
  };
}
