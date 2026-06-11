{config, ...}: {
  sops.templates."helm/synapse.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: synapse
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: matrix
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              # Roll the pod when the rendered config / signing key changes.
              secret.reloader.stakater.com/reload: "synapse-config"

          controllers:
            main:
              initContainers:
                copy-config:
                  image:
                    repository: busybox
                    tag: "1.38.0"
                  securityContext:
                    runAsUser: 0
                    runAsGroup: 0
                  command:
                    - sh
                    - -ceu
                    - |
                      mkdir -p /data/media
                      cp /secret/homeserver.yaml /data/homeserver.yaml
                      cp /secret/log.config     /data/log.config
                      cp /secret/signing.key    /data/signing.key
                      chown -R 991:991 /data
                      chmod 600 /data/homeserver.yaml /data/signing.key
                      echo "synapse config deployed"
              containers:
                main:
                  image:
                    repository: ghcr.io/element-hq/synapse
                    tag: "v1.153.0"
                  env:
                    TZ: "Europe/Helsinki"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /health
                          port: 8008
                        initialDelaySeconds: 30
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 5
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /health
                          port: 8008
                        initialDelaySeconds: 15
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 200m
                      memory: 512Mi
                    limits:
                      cpu: 2000m
                      memory: 2Gi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 8008
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: matrix-synapse-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/matrix/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            data:
              accessMode: ReadWriteOnce
              size: 20Gi
              storageClass: local-path
              globalMounts:
                - path: /data
            synapse-config:
              type: secret
              name: synapse-config
              advancedMounts:
                main:
                  copy-config:
                    - path: /secret
                      readOnly: true
    '';
    path = "/var/lib/rancher/k3s/server/manifests/synapse.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
