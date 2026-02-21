# RBAC for the Pangolin blueprint aggregator Job.
#
# The aggregator Job runs as ServiceAccount `pangolin-blueprint-aggregator`
# in the cicd namespace. It needs to:
#   - list/get all ConfigMaps with label pangolin.dobryops.com/resource=true
#   - get/create/update the master blueprint ConfigMap
#
# CI pipeline jobs (gitlab-runner SA) also need to delete+apply the Job
# manifest itself — that is covered by the existing gitlab-runner ClusterRole
# in aetherflow-backend/infra/argocd/rbac.yaml.
{ ... }:

{
  services.k3s.manifests.pangolin-aggregator-rbac.content = {
    apiVersion = "v1";
    kind = "List";
    items = [
      {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
          name      = "pangolin-blueprint-aggregator";
          namespace = "cicd";
        };
      }
      {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "Role";
        metadata = {
          name      = "pangolin-blueprint-aggregator";
          namespace = "cicd";
        };
        rules = [
          {
            apiGroups = [ "" ];
            resources = [ "configmaps" ];
            verbs     = [ "get" "list" "create" "update" "patch" ];
          }
        ];
      }
      {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "RoleBinding";
        metadata = {
          name      = "pangolin-blueprint-aggregator";
          namespace = "cicd";
        };
        subjects = [
          {
            kind      = "ServiceAccount";
            name      = "pangolin-blueprint-aggregator";
            namespace = "cicd";
          }
        ];
        roleRef = {
          kind     = "Role";
          name     = "pangolin-blueprint-aggregator";
          apiGroup = "rbac.authorization.k8s.io";
        };
      }
    ];
  };
}
