{ config, ... }:

{
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
        version: "9.5.1"
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

            ingress:
              enabled: true
              class: traefik
              configureCertmanager: false
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

            minio:
              enabled: false

            appConfig:
              object_store:
                enabled: true
                proxy_download: false
                connection:
                  secret: gitlab-minio-connection
                  key: connection
              lfs:
                enabled: true
                proxy_download: false
                bucket: gitlab-lfs
              artifacts:
                enabled: true
                proxy_download: false
                bucket: gitlab-artifacts
              uploads:
                enabled: true
                proxy_download: false
                bucket: gitlab-uploads
              packages:
                enabled: true
                proxy_download: false
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
            storage:
              secret: gitlab-registry-storage
              key: config

          installCertmanager: false

          nginx-ingress:
            enabled: false

          prometheus:
            install: false

          gitlab-runner:
            install: false

          gitlab:
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
              resources:
                requests:
                  cpu: 300m
                  memory: 1Gi
                limits:
                  cpu: 1
                  memory: 2.5Gi
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

          redis:
            master:
              resources:
                requests:
                  cpu: 100m
                  memory: 128Mi
                limits:
                  cpu: 500m
                  memory: 512Mi
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/gitlab.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
