{ config, ... }:

{
  sops.templates."helm/speedtest-tracker.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: speedtest-tracker
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: monitoring
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              secret.reloader.stakater.com/reload: "speedtest-tracker-env"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: lscr.io/linuxserver/speedtest-tracker
                    tag: "1.14.3"
                    pullPolicy: IfNotPresent
                  envFrom:
                    - secretRef:
                        name: speedtest-tracker-env
                  env:
                    TZ: "Europe/Sofia"
                    PUID: "1000"
                    PGID: "1000"
                    # Accept Ookla's EULA + GDPR notice — required on every
                    # boot or the underlying speedtest binary refuses to run.
                    OOKLA_EULA_GDPR: "true"
                    # Every 6h on the dot — see `man 5 crontab`. The
                    # speedtest takes ~30s and saturates the link briefly.
                    SPEEDTEST_SCHEDULE: "0 */6 * * *"
                    DB_CONNECTION: "sqlite"
                    APP_URL: "https://${config.sops.placeholder."pangolin/resources/speedtest/domain"}"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /api/healthcheck
                          port: 80
                        initialDelaySeconds: 60
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 3
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /api/healthcheck
                          port: 80
                        initialDelaySeconds: 30
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
                  # 8097 = uptime-kuma; 8098 next free was earmarked for
                  # searxng; speedtest takes 8099.
                  port: 8099
                  targetPort: 80
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: monitoring-speedtest-tracker-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/speedtest/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            config:
              accessMode: ReadWriteOnce
              size: 2Gi
              storageClass: local-path
              globalMounts:
                - path: /config
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/speedtest-tracker.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
