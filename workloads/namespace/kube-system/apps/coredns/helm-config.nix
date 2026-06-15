{...}: {
  services.k3s.manifests.coredns-config.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChartConfig";
    metadata = {
      name = "coredns";
      namespace = "kube-system";
    };
    spec.valuesContent = ''
      image:
        repository: rancher/mirrored-coredns-coredns
        tag: "1.14.4"
    '';
  };
}
