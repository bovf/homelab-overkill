{config, ...}: {
  sops.templates."helm/gitlab.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: gitlab
        namespace: kube-system
      spec:
        repo: https://charts.gitlab.io/
        chart: gitlab
        version: "10.5.4" # GitLab 19.5.3; native MCP is enabled by default.
        timeout: 30m
        targetNamespace: cicd
        createNamespace: false
        valuesContent: |
          global:
            hosts:
              domain: ${config.sops.placeholder."admin/base_domain"}
              gitlab:
                name: ${config.sops.placeholder."pangolin/resources/gitlab/domain"}
              registry:
                name: ${config.sops.placeholder."pangolin/resources/registry/domain"}

            # Chart 10 defaults to Envoy/Gateway API; retain our existing Traefik.
            gatewayApi:
              enabled: false
              installEnvoy: false
              configureCertmanager: false

            ingress:
              enabled: true
              provider: traefik
              class: traefik
              configureCertmanager: false
              # TLS terminates at traefik (with the *.dobryops.com
              # wildcard from cert-manager). Disabling tls on gitlab's
              # own Ingresses stops the chart from auto-generating a
              # self-signed wildcard secret and pulling it into traefik's
              # cert pool — which would override our real wildcard.
              tls:
                enabled: false
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure

            initialRootPassword:
              secret: gitlab-initial-root-password
              key: password

            psql:
              host: postgresql.database.svc.cluster.local
              port: 5432
              username: gitlab
              database: gitlabhq_production
              password:
                secret: gitlab-postgres-secret
                key: password

            redis:
              host: gitlab-redis-external.cicd.svc.cluster.local
              port: 6379
              auth:
                enabled: true
                secret: gitlab-redis-secret
                key: secret

            minio:
              enabled: false

            appConfig:
              backups:
                bucket: gitlab-backups
                tmpBucket: gitlab-tmp
              object_store:
                enabled: true
                # MinIO endpoint is cluster-internal DNS — browser-facing
                # presigned URLs can't resolve it. proxy_download streams the
                # bytes through the gitlab-webservice pod instead, keeping
                # the URL on gitlab.dobryops.com.
                proxy_download: true
                connection:
                  secret: gitlab-minio-connection
                  key: connection
              lfs:
                enabled: true
                proxy_download: true
                bucket: gitlab-lfs
              artifacts:
                enabled: true
                proxy_download: true
                bucket: gitlab-artifacts
              uploads:
                enabled: true
                proxy_download: true
                bucket: gitlab-uploads
              packages:
                enabled: true
                proxy_download: true
                bucket: gitlab-packages
              externalDiffs:
                enabled: false
              terraformState:
                enabled: false
              ciSecureFiles:
                enabled: false
              dependencyProxy:
                enabled: false

          registry:
            enabled: true
            ingress:
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: cicd-registry-headers@kubernetescrd
            # Tunnel-side ingress via sibling Service in external-services.nix;
            # the chart doesn't propagate externalIPs.
            storage:
              secret: gitlab-registry-storage
              key: config

          installCertmanager: false

          nginx-ingress:
            enabled: false

          prometheus:
            install: false

          gitlab-runner:
            install: true
            runnerRegistrationToken: ""
            replicas: 2
            gitlabUrl: http://gitlab-webservice-default.cicd.svc.cluster.local:8181
            runners:
              locked: null
              authenticationToken:
                secret: gitlab-gitlab-runner-secret
                key: runner-token
              config: |
                [[runners]]
                  executor = "kubernetes"
                  [runners.kubernetes]
                    namespace = "cicd"
                    image = "alpine:3.18"
                    cpu_limit = "1"
                    memory_limit = "1Gi"
                    cpu_request = "100m"
                    memory_request = "128Mi"
                    [runners.kubernetes.node_selector]
                      "kubernetes.io/arch" = "amd64"
            resources:
              requests:
                cpu: 250m
                memory: 256Mi
              limits:
                cpu: 1
                memory: 1Gi
            concurrency: 10
            checkInterval: 30

          gitlab:
            toolbox:
              backups:
                objectStorage:
                  backend: s3
                  config:
                    secret: gitlab-backup-storage
                    key: config
            gitaly:
              resources:
                requests:
                  cpu: 100m
                  memory: 200Mi
                limits:
                  cpu: 1
                  memory: 2Gi
              persistence:
                size: 50Gi
            gitlab-shell:
              resources:
                requests:
                  cpu: 50m
                  memory: 50Mi
                limits:
                  cpu: 200m
                  memory: 256Mi
            gitlab-exporter:
              enabled: false
            webservice:
              minReplicas: 1
              maxReplicas: 1
              # Tunnel-side ingress via sibling Service (external-services.nix).
              # 1 Puma worker = ~1.2 GB RSS; the chart default 2 workers
              # OOMKilled at the old 2.5 Gi limit.
              puma:
                workers: 1
              resources:
                requests:
                  cpu: 300m
                  memory: 1.5Gi
                limits:
                  cpu: 1
                  memory: 4Gi
            sidekiq:
              minReplicas: 1
              maxReplicas: 1
              resources:
                requests:
                  cpu: 100m
                  memory: 512Mi
                limits:
                  cpu: 1
                  memory: 2Gi

          postgresql:
            install: false

    '';
    path = "/var/lib/rancher/k3s/server/manifests/gitlab.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
