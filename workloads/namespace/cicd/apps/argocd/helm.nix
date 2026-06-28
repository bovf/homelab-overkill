{config, ...}: {
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
        version: "9.5.22"
        targetNamespace: cicd
        createNamespace: false
        valuesContent: |
          global:
            domain: ${config.sops.placeholder."pangolin/resources/argocd/domain"}
            image:
              tag: v3.4.4

          configs:
            params:
              "server.insecure": "true"
            cm:
              admin.enabled: true
              url: https://${config.sops.placeholder."pangolin/resources/argocd/domain"}
              exec.enabled: true
              # CI account; token regenerated on-demand and stored as
              # ARGOCD_AUTH_TOKEN in GitLab CI masked variables.
              accounts.ci: apiKey
              # Enable kustomize `helmCharts:` block — argocd-repo-server
              # invokes `kustomize build --enable-helm` so manifests that
              # inflate a helm chart inline render correctly.
              kustomize.buildOptions: "--enable-helm"
            secret:
              createSecret: true
              argocdServerAdminPassword: "${config.sops.placeholder."argocd/admin_password"}"
            rbac:
              policy.csv: |
                g, argocd-admins, role:admin
                g, argocd-readonly, role:readonly
                p, ci, applications, get,    */*, allow
                p, ci, applications, sync,   */*, allow
                p, ci, applications, update, */*, allow
                p, ci, projects,      get,    *, allow
                p, ci, repositories,  get,    *, allow
              scopes: "[groups]"

          controller:
            replicas: 1
            image:
              tag: v3.4.4
            extraArgs:
              - --repo-server-timeout-seconds=180
            resources:
              requests:
                cpu: 250m
                memory: 512Mi
              limits:
                cpu: 1
                memory: 2Gi

          dex:
            enabled: false

          redisSecretInit:
            # The existing argocd-redis secret is already present. On upgrades
            # the 9.x chart's pre-upgrade secret-init hook can time out under
            # k3s HelmChart and block the whole Argo CD image upgrade.
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
                memory: 512Mi
              limits:
                cpu: 500m
                memory: 2Gi
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
            # Service port bumped to clear the tunnel-side port-80 collision.
            service:
              servicePortHttp: 8090
              servicePortHttps: 443
              externalIPs:
                - "100.89.128.16"
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

    '';
    path = "/var/lib/rancher/k3s/server/manifests/argocd.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
