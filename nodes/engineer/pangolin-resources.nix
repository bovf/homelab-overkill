# Host-level pangolin resources for engineer. The targets point at the
# kwg tunnel IP (100.89.128.16); sshd and the k3s API server both bind
# all-interfaces, so they're reachable on that IP directly.
{ ... }:

{
  workloads.pangolinResources.engineer_ssh = {
    name           = "Engineer SSH";
    protocol       = "tcp";
    proxyPortKey   = "pangolin/resources/engineer_ssh/port";
    # Off by default — toggle on in the Pangolin UI when remote SSH or
    # k8s API access is needed; the blueprint sync respects `false` and
    # won't fight UI changes (same pattern as the cam resource).
    enabled        = false;
    targetHostname = "100.89.128.16";
    targetPort     = 22;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
  };

  workloads.pangolinResources.engineer_k8s_api = {
    name           = "Engineer K8s API";
    protocol       = "tcp";
    proxyPortKey   = "pangolin/resources/engineer_k8s_api/port";
    # Off by default — toggle on in the Pangolin UI when remote SSH or
    # k8s API access is needed; the blueprint sync respects `false` and
    # won't fight UI changes (same pattern as the cam resource).
    enabled        = false;
    targetHostname = "100.89.128.16";
    targetPort     = 6443;
    newtInstance   = "engineer-kernel";
    viaKernelWg    = true;
  };

  sops.secrets."pangolin/resources/engineer_ssh/port"     = {};
  sops.secrets."pangolin/resources/engineer_k8s_api/port" = {};
}
