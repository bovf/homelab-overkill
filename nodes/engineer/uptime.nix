# Host-level monitors that don't belong to any workload — engineer's
# SSH daemon and the k3s API server. Probed via TCP handshake against
# the node's LAN IP from inside the cluster.
#
# The pangolin TCP resources (engineer_ssh, engineer_k8s_api) tunnel
# these through the VPS for off-LAN reach, but we don't monitor the
# public path here — it'd be testing pangolin, not the host. The
# Private group keeps these off the public status page.
{ ... }:

{
  workloads.uptimeMonitors.engineer_ssh = {
    name  = "Engineer SSH";
    type  = "port";
    host  = "192.0.2.10";
    port  = 22;
    group = "Private";
    tags  = [ "host" ];
  };

  workloads.uptimeMonitors.engineer_k8s_api = {
    name  = "Engineer k8s API";
    type  = "port";
    host  = "192.0.2.10";
    port  = 6443;
    group = "Private";
    tags  = [ "host" ];
  };
}
