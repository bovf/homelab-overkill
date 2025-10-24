{ config, ... }:

{
  sops = {
    templates."pangolin/newt-secret.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: newt-secrets
          namespace: pangolin
        type: Opaque
        stringData:
          newt_id: "${config.sops.placeholder."pangolin/newt_id"}"
          newt_secret: "${config.sops.placeholder."pangolin/newt_secret"}"
      '';
      path = "/var/lib/rancher/k3s/server/manifests/newt-secret.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
  };
}

