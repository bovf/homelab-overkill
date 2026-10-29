{...}: {
  # Node Feature Discovery
  services.k3s.manifests.nfd.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "node-feature-discovery";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://kubernetes-sigs.github.io/node-feature-discovery/charts";
      chart = "node-feature-discovery";
      version = "0.20.1";
      targetNamespace = "kube-system";
      createNamespace = false;
      valuesContent = ''
        tolerations:
          - operator: Exists
        nodeSelector: {}
        image:
          tag: "v0.20.1@sha256:6fc5c9af9176e1acb5ce57a4a1d0c0d3eb25cd34f5bdd0efefebf0efe45a8379"
        # Additional NFD-specific config can go here
      '';
    };
  };
}
