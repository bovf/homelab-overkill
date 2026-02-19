{ config, ... }:

{
  sops.templates = {
    "argocd/gitlab-repo-credentials.yaml" = {
      content = ''
        apiVersion: v1
        kind: Secret
        metadata:
          name: gitlab-repo-credentials
          namespace: cicd
          labels:
            argocd.argoproj.io/secret-type: repo-creds
        type: Opaque
        stringData:
          type: git
          url: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}
          password: "${config.sops.placeholder."argocd/gitlab_token"}"
          username: oauth2
      '';
      path = "/var/lib/rancher/k3s/server/manifests/argocd-gitlab-repo-credentials.yaml";
      owner = "root";
      group = "root";
      mode = "0644";
    };
  };
}
