# Host-level Pangolin resources through engineer's kwg tunnel IP.
# Engineer SSH/k3s bind directly; Heavy SSH is DNAT'd to the workstation.
{...}: {
  workloads.pangolinResources.engineer_ssh = {
    name = "Engineer SSH";
    protocol = "tcp";
    proxyPortKey = "pangolin/resources/engineer_ssh/port";
    # Enable manually in Pangolin when needed; blueprint sync resets it to off.
    enabled = false;
    targetHostname = "100.89.128.16";
    targetPort = 22;
    newtInstance = "engineer-kernel";
    viaKernelWg = true;
  };

  workloads.pangolinResources.heavy_ssh = {
    name = "Heavy SSH";
    protocol = "tcp";
    proxyPortKey = "pangolin/resources/heavy_ssh/port";
    # Enable manually in Pangolin when needed; blueprint sync resets it to off.
    enabled = false;
    targetHostname = "100.89.128.16";
    targetPort = 2224;
    newtInstance = "engineer-kernel";
    viaKernelWg = true;
  };

  workloads.pangolinResources.engineer_k8s_api = {
    name = "Engineer K8s API";
    protocol = "tcp";
    proxyPortKey = "pangolin/resources/engineer_k8s_api/port";
    # Keep the Kubernetes API reachable through the kernel-WG Pangolin resource.
    enabled = true;
    targetHostname = "100.89.128.16";
    targetPort = 6443;
    newtInstance = "engineer-kernel";
    viaKernelWg = true;
  };

  sops.secrets."pangolin/resources/engineer_ssh/port" = {};
  sops.secrets."pangolin/resources/heavy_ssh/port" = {};
  sops.secrets."pangolin/resources/engineer_k8s_api/port" = {};
}
