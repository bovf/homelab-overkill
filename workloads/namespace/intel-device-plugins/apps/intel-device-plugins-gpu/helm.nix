{ ... }:

{
  services.k3s.manifests.intel-device-plugins-gpu.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "intel-device-plugins-gpu";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://intel.github.io/helm-charts/";
      chart = "intel-device-plugins-gpu";
      version = "0.32.0";
      targetNamespace = "intel-device-plugins";
      createNamespace = false;
      valuesContent = ''
        sharedDevNum: 2
      '';
    };
  };
}
