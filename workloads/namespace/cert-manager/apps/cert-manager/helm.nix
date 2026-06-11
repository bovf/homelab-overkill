{...}: {
  services.k3s.manifests.cert-manager-helm.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "cert-manager";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://charts.jetstack.io";
      chart = "cert-manager";
      version = "v1.20.2";
      targetNamespace = "cert-manager";
      createNamespace = false;
      valuesContent = ''
        installCRDs: true
      '';
    };
  };
}
