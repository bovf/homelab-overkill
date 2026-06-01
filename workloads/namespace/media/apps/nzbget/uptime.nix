{ ... }:

# Pangolin path disabled — probe the cluster-internal Service.
{
  workloads.uptimeMonitors.nzbget = {
    name  = "NZBGet";
    url   = "http://nzbget.media.svc.cluster.local:6789";
    group = "Private";
  };
}
