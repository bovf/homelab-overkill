# CI-owned newt instance. Blueprint is aggregated from labelled
# ConfigMaps in cicd by cronjob.nix, not via sops.
{ ... }:

{
  workloads.pangolinInstances.cicd-gitops = {
    endpointKey = "pangolin/instances/cicd-gitops/endpoint";
    idKey       = "pangolin/instances/cicd-gitops/newt_id";
    secretKey   = "pangolin/instances/cicd-gitops/newt_secret";
    siteIdKey   = "pangolin/instances/cicd-gitops/site_id";
  };
}
