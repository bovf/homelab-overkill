{ config, nodeName, ... }:

{
  sops = {
    # Declare the per-instance SOPS secrets so sops-nix decrypts them at boot.
    secrets."pangolin/instances/${nodeName}/endpoint"    = {};
    secrets."pangolin/instances/${nodeName}/newt_id"     = {};
    secrets."pangolin/instances/${nodeName}/newt_secret" = {};
    secrets."pangolin/instances/${nodeName}/site_id"     = {};

    # Render the Kubernetes Secret for the newt credentials.
    # Written to k3s auto-apply dir so it exists before the newt pod starts.
    templates."pangolin/newt-secret-${nodeName}.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: newt-cred
          namespace: pangolin
        type: Opaque
        stringData:
          PANGOLIN_ENDPOINT: "${config.sops.placeholder."pangolin/instances/${nodeName}/endpoint"}"
          NEWT_ID: "${config.sops.placeholder."pangolin/instances/${nodeName}/newt_id"}"
          NEWT_SECRET: "${config.sops.placeholder."pangolin/instances/${nodeName}/newt_secret"}"
      '';
      path  = "/var/lib/rancher/k3s/server/manifests/newt-secret.yaml";
      owner = "root";
      group = "root";
      mode  = "0644";
    };
  };
}
