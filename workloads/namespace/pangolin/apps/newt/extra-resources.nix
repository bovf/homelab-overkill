# Pangolin resources that are not owned by any other workload.
# Examples: the Traefik dashboard (served by k3s built-in Traefik, no separate
# workload dir), raw port exposures, or any ad-hoc service you want to tunnel
# without adding a full workload definition.
#
# Add entries here following the same pattern as per-app pangolin-blueprint.nix
# files.  The newtInstance field should match the node name for this cluster.
{ nodeName, ... }:

{
  # Traefik dashboard — served by the built-in k3s Traefik; no separate workload.
  workloads.pangolinResources.traefik_dashboard = {
    name           = "Traefik Dashboard";
    protocol       = "http";
    domainKey      = "pangolin/resources/traefik_dashboard/domain";
    enabled        = true;
    ssoEnabled     = true;
    targetHostname = "traefik.kube-system.svc.cluster.local";
    targetMethod   = "https";
    targetPort     = 443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/traefik_dashboard/domain" = {};

  # ---------------------------------------------------------------------------
  # Infrastructure TCP tunnels — host-level services exposed via Pangolin
  # ---------------------------------------------------------------------------

  # Engineer SSH — raw TCP tunnel to the host's SSH daemon
  workloads.pangolinResources.engineer_ssh = {
    name           = "Engineer SSH";
    protocol       = "tcp";
    proxyPortKey   = "pangolin/resources/engineer_ssh/port";
    enabled        = true;
    targetHostname = "192.0.2.10";
    targetPort     = 22;
    newtInstance   = nodeName;
  };

  # Engineer K8s API — raw TCP tunnel to the k3s API server
  workloads.pangolinResources.engineer_k8s_api = {
    name           = "Engineer K8s API";
    protocol       = "tcp";
    proxyPortKey   = "pangolin/resources/engineer_k8s_api/port";
    enabled        = true;
    targetHostname = "192.0.2.10";
    targetPort     = 6443;
    newtInstance   = nodeName;
  };

  sops.secrets."pangolin/resources/engineer_ssh/port" = {};
  sops.secrets."pangolin/resources/engineer_k8s_api/port" = {};
  # Note: engineer_ssh/domain and engineer_k8s_api/domain are NOT declared
  # as sops.secrets — they are only consumed at runtime by nix apps (devShell
  # SSH config and kubeconfig bootstrap), not by sops-nix on the node.
}
