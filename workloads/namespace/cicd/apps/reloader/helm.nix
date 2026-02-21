{ ... }:

{
  services.k3s.manifests.reloader.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "reloader";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://stakater.github.io/stakater-charts";
      chart = "reloader";
      targetNamespace = "cicd";
      createNamespace = false;
      valuesContent = ''
        reloader:
          watchGlobally: true
          resources:
            requests:
              cpu: 10m
              memory: 32Mi
            limits:
              cpu: 100m
              memory: 128Mi
      '';
    };
  };
}
