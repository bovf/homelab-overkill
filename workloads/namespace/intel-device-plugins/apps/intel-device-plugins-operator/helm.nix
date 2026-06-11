{...}: {
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
      version = "0.36.0";
      targetNamespace = "intel-device-plugins";
      createNamespace = false;
      valuesContent = ''
        manager:
          image:
            # Force a one-time pod-template change after adding the 0.36.x NPU
            # CRD. The existing pod started before the CRD was registered and
            # keeps crashing on a stale discovery view until it is replaced.
            pullPolicy: Always
      '';
    };
  };
}
