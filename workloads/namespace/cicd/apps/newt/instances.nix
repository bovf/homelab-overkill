# Registers the cicd-gitops Pangolin/Newt instance.
#
# This is a CI/CD-owned Newt that tunnels all ArgoCD-managed services through
# a dedicated Pangolin site — completely separate from the engineer (homelab)
# Newt. Its blueprint is NOT managed by sops-nix/NixOS. Instead a Kubernetes
# Job (job.nix) aggregates labelled ConfigMaps from ArgoCD-managed services
# into the master `pangolin-blueprint-cicd-gitops` ConfigMap, and Reloader
# rolls the Newt pod automatically when it changes.
#
# To add a new ArgoCD-managed service to this tunnel:
#   1. In the app repo: create infra/argocd/pangolin/resource.yaml.tpl
#      (a ConfigMap with label `pangolin.dobryops.com/resource: "true"`)
#   2. In the CI pipeline: envsubst + kubectl apply, then trigger the
#      aggregator job (kubectl delete+apply job/pangolin-blueprint-aggregator)
#   3. Done — Reloader handles the Newt restart. No homelab-overkill changes.
{ ... }:

{
  workloads.pangolinInstances.cicd-gitops = {
    endpointKey = "pangolin/instances/cicd-gitops/endpoint";
    idKey       = "pangolin/instances/cicd-gitops/newt_id";
    secretKey   = "pangolin/instances/cicd-gitops/newt_secret";
    siteIdKey   = "pangolin/instances/cicd-gitops/site_id";
  };
}
