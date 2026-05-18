{ config, ... }:

{
  sops = {
    secrets."pangolin/instances/cicd-gitops/endpoint"    = {};
    secrets."pangolin/instances/cicd-gitops/newt_id"     = {};
    secrets."pangolin/instances/cicd-gitops/newt_secret" = {};
    secrets."pangolin/instances/cicd-gitops/site_id"     = {};

    templates."pangolin/newt-secret-cicd-gitops.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: newt-cred-cicd-gitops
          namespace: cicd
        type: Opaque
        stringData:
          PANGOLIN_ENDPOINT: "${config.sops.placeholder."pangolin/instances/cicd-gitops/endpoint"}"
          NEWT_ID: "${config.sops.placeholder."pangolin/instances/cicd-gitops/newt_id"}"
          NEWT_SECRET: "${config.sops.placeholder."pangolin/instances/cicd-gitops/newt_secret"}"
      '';
      path  = "/var/lib/rancher/k3s/server/manifests/newt-secret-cicd-gitops.yaml";
      owner = "root";
      group = "root";
      mode  = "0644";
    };
  };
}
