{config, ...}: {
  sops.templates."helm/romm.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: romm
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              secret.reloader.stakater.com/reload: "romm-credentials"
            securityContext:
              runAsUser: 1000
              runAsGroup: 1000
              runAsNonRoot: true
              fsGroup: 1000
              fsGroupChangePolicy: OnRootMismatch

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: docker.io/rommapp/romm
                    tag: "5.0.0@sha256:91f6611eca5a4dafc4f4a1d72a1ed7dd66a11375d939f28410dc1d1de0b80b1b"
                  envFrom:
                    - secretRef:
                        name: romm-credentials
                  env:
                    TZ: "Europe/Helsinki"
                    ROMM_BASE_URL: "https://${config.sops.placeholder."pangolin/resources/romm/domain"}"
                    ROMM_DB_DRIVER: "postgresql"
                    DB_HOST: "postgresql.database.svc.cluster.local"
                    DB_PORT: "5432"
                    DB_NAME: "romm"
                    DB_USER: "romm"
                    HASHEOUS_API_ENABLED: "true"
                    HLTB_API_ENABLED: "true"
                    PLAYMATCH_API_ENABLED: "true"
                    ENABLE_RESCAN_ON_FILESYSTEM_CHANGE: "true"
                    RESCAN_ON_FILESYSTEM_CHANGE_DELAY: "5"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /api/heartbeat
                          port: 8080
                        initialDelaySeconds: 120
                        periodSeconds: 30
                        timeoutSeconds: 10
                        failureThreshold: 5
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /api/heartbeat
                          port: 8080
                        initialDelaySeconds: 20
                        periodSeconds: 15
                        timeoutSeconds: 10
                        failureThreshold: 5

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 8105
                  targetPort: 8080
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-romm-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/romm/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 8105

          persistence:
            appdata:
              size: 10Gi
              accessMode: ReadWriteOnce
              advancedMounts:
                main:
                  main:
                    - path: /romm
            library:
              existingClaim: media-pvc
              advancedMounts:
                main:
                  main:
                    - path: /romm/library
            valkey:
              size: 1Gi
              accessMode: ReadWriteOnce
              advancedMounts:
                main:
                  main:
                    - path: /redis-data
    '';
    path = "/var/lib/rancher/k3s/server/manifests/romm.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
