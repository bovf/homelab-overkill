# SA / Role for the pangolin blueprint aggregator CronJob. CI's
# gitlab-runner SA has its own ClusterRole to manage the Job itself.
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
