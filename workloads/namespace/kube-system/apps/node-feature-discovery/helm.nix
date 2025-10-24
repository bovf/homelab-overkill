{ ... }:

{
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
      version = "0.17.3"; # Latest stable as of mid-2025, adjust if needed
      targetNamespace = "kube-system";
      createNamespace = false;
      valuesContent = ''
        tolerations:
          - operator: Exists
        nodeSelector: {}
        image:
          tag: "v0.17.3"
        # Additional NFD-specific config can go here
      '';
    };
  };
}
