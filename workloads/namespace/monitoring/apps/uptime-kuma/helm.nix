{ config, ... }:

{
  sops.templates."helm/uptime-kuma.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: uptime-kuma
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: monitoring
        createNamespace: false
        valuesContent: |
          controllers:
            main:
              containers:
                main:
                  image:
                    repository: louislam/uptime-kuma
                    tag: "1.23.16"
                    pullPolicy: IfNotPresent
                  env:
                    TZ: "Europe/Sofia"
                    UPTIME_KUMA_DISABLE_FRAME_SAMEORIGIN: "true"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 3001
                        initialDelaySeconds: 60
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 3
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 3001
                        initialDelaySeconds: 30
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 50m
                      memory: 128Mi
                    limits:
                      cpu: 500m
                      memory: 512Mi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  # Tunnel-IP port — 8088/8089/8091/8092/8093/8094/8095/8096
                  # are taken; 8097 is next free.
                  port: 8097
                  targetPort: 3001
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: monitoring-uptime-kuma-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/uptime/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            data:
              accessMode: ReadWriteOnce
              size: 2Gi
              storageClass: local-path
              globalMounts:
                - path: /app/data
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/uptime-kuma.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
