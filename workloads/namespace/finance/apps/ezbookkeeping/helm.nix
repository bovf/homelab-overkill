{config, ...}: {
  sops.templates."helm/ezbookkeeping.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: ezbookkeeping
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: finance
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              # Roll the pod when the DB password / secret key changes.
              secret.reloader.stakater.com/reload: "ezbookkeeping-credentials"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: docker.io/mayswind/ezbookkeeping
                    tag: "1.5.1"
                  # EBK_DATABASE_PASSWD and EBK_SECURITY_SECRET_KEY come from
                  # the ezbookkeeping-credentials secret (keys named to match).
                  envFrom:
                    - secretRef:
                        name: ezbookkeeping-credentials
                  env:
                    TZ: "Europe/Helsinki"
                    # Postgres backend — provisioned by the
                    # postgresql-ezbookkeeping-init Job in the database ns.
                    EBK_DATABASE_TYPE: "postgres"
                    EBK_DATABASE_HOST: "postgresql.database.svc.cluster.local:5432"
                    EBK_DATABASE_NAME: "ezbookkeeping"
                    EBK_DATABASE_USER: "ezbookkeeping"
                    EBK_DATABASE_SSL_MODE: "disable"
                    # TLS is terminated upstream (pangolin VPS / traefik), so
                    # the app speaks plain HTTP but must emit https links.
                    EBK_SERVER_PROTOCOL: "http"
                    EBK_SERVER_HTTP_ADDR: "0.0.0.0"
                    EBK_SERVER_HTTP_PORT: "8080"
                    EBK_SERVER_DOMAIN: "${config.sops.placeholder."pangolin/resources/ezbookkeeping/domain"}"
                    EBK_SERVER_ROOT_URL: "https://${config.sops.placeholder."pangolin/resources/ezbookkeeping/domain"}/"
                    # Log to stdout only — no writable log dir needed.
                    EBK_LOG_MODE: "console"
                    # Uploaded receipt images / avatars land on the PVC.
                    EBK_STORAGE_TYPE: "local_filesystem"
                    EBK_STORAGE_LOCAL_FILESYSTEM_PATH: "/ezbookkeeping/storage"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 8080
                        initialDelaySeconds: 20
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 3
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 8080
                        initialDelaySeconds: 10
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 50m
                      memory: 128Mi
                    limits:
                      cpu: 1000m
                      memory: 512Mi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  # Unique tunnel-IP port — every kwg-routed service shares
                  # the 100.89.128.16 externalIP, so ports must not collide
                  # (8080 clashed with qbittorrent). Pod still listens 8080.
                  port: 8093
                  targetPort: 8080
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: finance-ezbookkeeping-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/ezbookkeeping/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            storage:
              accessMode: ReadWriteOnce
              size: 2Gi
              storageClass: local-path
              globalMounts:
                - path: /ezbookkeeping/storage
    '';
    path = "/var/lib/rancher/k3s/server/manifests/ezbookkeeping.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
