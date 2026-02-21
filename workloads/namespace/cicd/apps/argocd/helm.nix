{ config, ... }:

{
  sops.templates."helm/argocd.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: argocd
        namespace: kube-system
      spec:
        repo: https://argoproj.github.io/argo-helm
        chart: argo-cd
        version: "7.7.17"
        targetNamespace: cicd
        createNamespace: false
        valuesContent: |
          global:
            domain: ${config.sops.placeholder."pangolin/resources/argocd/domain"}

          configs:
            params:
              "server.insecure": "true"
            cm:
              admin.enabled: true
              url: https://${config.sops.placeholder."pangolin/resources/argocd/domain"}
              exec.enabled: true
              # CI account – token is generated on-demand and stored as
              # ARGOCD_AUTH_TOKEN in GitLab CI masked variables. Never stored here.
              # To (re-)generate after deploy:
              #   kubectl exec -n cicd deploy/argocd-server -- \
              #     argocd account generate-token \
              #       --account ci \
              #       --server argocd-server.cicd.svc.cluster.local \
              #       --plaintext \
              #       --grpc-web
              accounts.ci: apiKey
            secret:
              createSecret: true
              argocdServerAdminPassword: "${config.sops.placeholder."argocd/admin_password"}"
            rbac:
              policy.csv: |
                g, argocd-admins, role:admin
                g, argocd-readonly, role:readonly
                p, ci, applications, get,  */*, allow
                p, ci, applications, sync, */*, allow
                p, ci, projects,      get,  *, allow
                p, ci, repositories,  get,  *, allow
              scopes: "[groups]"

          controller:
            replicas: 1
            resources:
              requests:
                cpu: 250m
                memory: 512Mi
              limits:
                cpu: 1
                memory: 2Gi

          dex:
            enabled: false

          redis:
            enabled: true
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                cpu: 250m
                memory: 256Mi

          repoServer:
            replicas: 1
            resources:
              requests:
                cpu: 100m
                memory: 256Mi
              limits:
                cpu: 500m
                memory: 512Mi
            env:
              - name: ARGOCD_EXEC_TIMEOUT
                value: "180s"

          applicationSet:
            replicas: 1
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                cpu: 250m
                memory: 256Mi

          server:
            replicas: 1
            extraArgs:
              - --insecure
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                cpu: 500m
                memory: 256Mi
            ingress:
              enabled: true
              ingressClassName: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              hosts:
                - ${config.sops.placeholder."pangolin/resources/argocd/domain"}
              tls: false

          notifications:
            enabled: false

          applicationController:
            extraArgs:
              - --repo-server-timeout-seconds=180
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/argocd.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
