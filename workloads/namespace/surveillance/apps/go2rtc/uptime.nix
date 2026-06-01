# Pangolin path is disabled for cam (hot mic + cam, public exposure off
# by default). Monitor the cluster-internal Service instead so we still
# know if go2rtc is alive without poking the public domain.
{ ... }:

{
  workloads.uptimeMonitors.cam = {
    name  = "Home Cam";
    url   = "http://go2rtc.surveillance.svc.cluster.local:8095/api/streams";
    group = "Private";
    tags  = [ "internal-only" ];
  };
}
