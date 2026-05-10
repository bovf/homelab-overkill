{ ... }:

{
  services.k3s.manifests.nova-serviceaccount.content = {
    apiVersion = "v1";
    kind = "ServiceAccount";
    metadata = {
      name = "nova";
      namespace = "monitoring";
    };
  };

  services.k3s.manifests.nova-clusterrole.content = {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "ClusterRole";
    metadata.name = "nova";
    rules = [
      # Helm 3 release storage (cluster-scoped Secrets in each namespace
      # carrying the rendered chart manifests).
      {
        apiGroups = [ "" ];
        resources = [ "secrets" "namespaces" "configmaps" ];
        verbs = [ "get" "list" "watch" ];
      }
      # k3s native HelmChart CRD (helm-controller writes these).
      {
        apiGroups = [ "helm.cattle.io" ];
        resources = [ "helmcharts" "helmchartconfigs" ];
        verbs = [ "get" "list" "watch" ];
      }
    ];
  };

  services.k3s.manifests.nova-clusterrolebinding.content = {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "ClusterRoleBinding";
    metadata.name = "nova";
    subjects = [{
      kind = "ServiceAccount";
      name = "nova";
      namespace = "monitoring";
    }];
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io";
      kind = "ClusterRole";
      name = "nova";
    };
  };
}
