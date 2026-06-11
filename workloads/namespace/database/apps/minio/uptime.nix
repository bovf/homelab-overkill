{...}:
# minio_console Pangolin resource is disabled (S3 API is exposed, the
# admin console is not). Probe the cluster-internal Service.
{
  workloads.uptimeMonitors.minio = {
    name = "MinIO Console";
    url = "http://minio-console.database.svc.cluster.local:9001";
    group = "Private";
  };

  workloads.uptimeMonitors.minio_api = {
    name = "MinIO API";
    url = "http://minio.database.svc.cluster.local:9000/minio/health/live";
    group = "Private";
  };
}
