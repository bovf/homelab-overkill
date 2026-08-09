{config, ...}: {
  sops.templates."helm/nzbget.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: nzbget
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
              k3s.cattle.io/config-version: "3"
              secret.reloader.stakater.com/reload: "nzbget-conf"
            securityContext:
              fsGroup: 1000

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
                      mkdir -p /config
                      mkdir -p /downloads/complete /downloads/intermediate /downloads/tmp /downloads/nzb /downloads/queue /downloads/scripts /downloads/tv /downloads/movies /downloads/roms
                      cp /secret/nzbget.conf /config/nzbget.conf
                      chown -R 1000:1000 /config
                      chmod -R u+rwX,g+rwX,o+rX /config
                      chown 1000:1000 /downloads /downloads/complete /downloads/intermediate /downloads/tmp /downloads/nzb /downloads/queue /downloads/scripts /downloads/tv /downloads/movies /downloads/roms
                      chmod 2775 /downloads /downloads/complete /downloads/intermediate /downloads/tmp /downloads/nzb /downloads/queue /downloads/scripts /downloads/tv /downloads/movies /downloads/roms
                      echo "nzbget.conf deployed successfully"
              containers:
                main:
                  image:
                    repository: lscr.io/linuxserver/nzbget
                    tag: "version-v26.1"
                  env:
                    TZ: "Europe/Helsinki"
                    PUID: "1000"
                    PGID: "1000"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 6789
                        initialDelaySeconds: 30
                        periodSeconds: 30
                        timeoutSeconds: 10
                        failureThreshold: 3
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 6789
                        initialDelaySeconds: 10
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 100m
                      memory: 256Mi
                    limits:
                      cpu: 500m
                      memory: 8Gi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 6789
                  protocol: HTTP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-nzbget-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/nzbget/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 6789

          persistence:
            config:
              accessMode: ReadWriteOnce
              size: 2Gi
              storageClass: local-path
              globalMounts:
                - path: /config
            downloads:
              existingClaim: media-pvc
              globalMounts:
                - path: /downloads
            nzbget-conf:
              type: secret
              name: nzbget-conf
              advancedMounts:
                main:
                  copy-config:
                    - path: /secret
                      readOnly: true
    '';
    path = "/var/lib/rancher/k3s/server/manifests/nzbget.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
