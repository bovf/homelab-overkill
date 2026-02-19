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
  # Add additional newt-owned resources below as needed, for example:
  #
  #   workloads.pangolinResources.my_raw_port = {
  #     name           = "My Raw Service";
  #     protocol       = "http";
  #     domainKey      = "pangolin/resources/my_raw_port/domain";
  #     enabled        = false;
  #     ssoEnabled     = true;
  #     targetHostname = "my-pod.my-namespace.svc.cluster.local";
  #     targetMethod   = "http";
  #     targetPort     = 1025;
  #     newtInstance   = nodeName;
  #   };
  #   sops.secrets."pangolin/resources/my_raw_port/domain" = {};
  # ---------------------------------------------------------------------------
}
