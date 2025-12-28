{ config, ... }:

{
  sops = {
    templates."pangolin/newt-secret.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: newt-cred
          namespace: pangolin
        type: Opaque
        stringData:
          PANGOLIN_ENDPOINT: "https://pangolin.dobryops.com"
          NEWT_ID: "${config.sops.placeholder."pangolin/newt_id"}"
          NEWT_SECRET: "${config.sops.placeholder."pangolin/newt_secret"}"
      '';
      # k3s auto-applies everything under server/manifests
      path = "/var/lib/rancher/k3s/server/manifests/newt-secret.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
  };
}
