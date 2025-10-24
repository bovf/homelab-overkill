{ ... }:

{
  services.k3s.manifests.intel-device-plugins-operator.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "intel-device-plugins-operator";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://intel.github.io/helm-charts/";
      chart = "intel-device-plugins-operator";
      version = "0.32.0";
      targetNamespace = "intel-device-plugins";
      createNamespace = false;
      valuesContent = '''';
    };
  };
}
