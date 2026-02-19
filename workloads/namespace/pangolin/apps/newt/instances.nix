# Registers this node as a Pangolin/Newt instance.
# The instance name equals nodeName so it automatically matches the cluster
# the flake is being built for (e.g. "engineer", "sentry-level-01").
# To add a second cluster: enable it in flake.nix — this file generates the
# correct instance registration automatically via nodeName.
{ nodeName, ... }:

{
  workloads.pangolinInstances.${nodeName} = {
    endpointKey = "pangolin/instances/${nodeName}/endpoint";
    idKey       = "pangolin/instances/${nodeName}/newt_id";
    secretKey   = "pangolin/instances/${nodeName}/newt_secret";
    siteIdKey   = "pangolin/instances/${nodeName}/site_id";
  };
}
