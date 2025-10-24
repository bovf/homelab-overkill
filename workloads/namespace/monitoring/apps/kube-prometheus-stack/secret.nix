{ config, ... }:

{
  sops.templates = {
    "monitoring/grafana-admin-password.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: grafana-admin-password
          namespace: monitoring
        type: Opaque
        stringData:
          admin-user: admin
          admin-password: "${config.sops.placeholder."monitoring/grafana-admin-password"}"
      '';
      path = "/var/lib/rancher/k3s/server/manifests/grafana-admin-password.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
  };
}
