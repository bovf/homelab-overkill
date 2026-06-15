{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.metallb;
in {
  config = mkIf cfg.enable {
    services.k3s.manifests.metallb.content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChart";
      metadata = {
        name = "metallb";
        namespace = "kube-system";
      };
      spec = {
        repo = "https://metallb.github.io/metallb";
        chart = "metallb";
        version = cfg.chartVersion;
        targetNamespace = cfg.namespace;
        createNamespace = true;
        valuesContent = ''
          controller:
            tolerations:
              - operator: Exists
          speaker:
            tolerations:
              - operator: Exists
          frr-k8s:
            frrk8s:
              frr:
                image:
                  tag: 10.6.1
        '';
      };
    };
  };
}
