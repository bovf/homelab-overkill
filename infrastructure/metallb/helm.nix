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
          # This cluster uses only L2Advertisement; the FRR backend is for BGP.
          frrk8s:
            enabled: false
          controller:
            tolerations:
              - operator: Exists
          speaker:
            tolerations:
              - operator: Exists
        '';
      };
    };
  };
}
