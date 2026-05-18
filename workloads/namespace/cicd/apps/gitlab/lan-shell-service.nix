# LAN LoadBalancer for git-over-SSH. Rendered via sops.templates so the
# user-facing port stays in the encrypted secrets file rather than the
# nix store. Shares 192.168.2.21 with the auto-generated `gitlab-lan`
# Service via MetalLB allow-shared-ip.
{ config, ... }:

{
  sops.templates."gitlab/gitlab-shell-lan.yaml" = {
    content = ''
      apiVersion: v1
      kind: Service
      metadata:
        name: gitlab-shell-lan
        namespace: cicd
        annotations:
          metallb.io/allow-shared-ip: "gitlab"
        labels:
          app: gitlab-shell-lan
          homelab.dobryops.com/lan-target: gitlab-gitlab-shell
      spec:
        type: LoadBalancer
        loadBalancerIP: 192.168.2.21
        selector:
          app: gitlab-shell
          release: gitlab
        ports:
          - name: ssh
            port: ${config.sops.placeholder."pangolin/resources/gitlab_ssh/port"}
            targetPort: 2222
            protocol: TCP
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/gitlab-shell-lan.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
