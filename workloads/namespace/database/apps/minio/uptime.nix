{ ... }:

# minio_console Pangolin resource is disabled (S3 API is exposed, the
# admin console is not). Probe the cluster-internal Service.
{
  workloads.uptimeMonitors.minio = {
    name  = "MinIO";
    url   = "http://minio-console.database.svc.cluster.local:9001";
    group = "Private";
  };
}
