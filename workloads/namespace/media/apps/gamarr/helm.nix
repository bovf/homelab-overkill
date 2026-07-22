{config, ...}: {
  sops.templates."helm/gamarr.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: gamarr
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            securityContext:
              fsGroup: 1000
              fsGroupChangePolicy: OnRootMismatch

          controllers:
            main:
              initContainers:
                init-library:
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
                      mkdir -p /media/roms
                      chown 1000:1000 /media/roms
                      chmod 0775 /media/roms
              containers:
                main:
                  image:
                    repository: ghcr.io/gamarr-app/gamarr
                    tag: "1.0.1@sha256:50c7a61e7753e8cb7aafa37d18fc04a054b4aa977e1faf4a95d80f886df8f553"
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
                          path: /ping
                          port: 6767
                        initialDelaySeconds: 60
                        periodSeconds: 30
                        failureThreshold: 5
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /ping
                          port: 6767
                        initialDelaySeconds: 15
                        periodSeconds: 15
                        failureThreshold: 5

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 8103
                  targetPort: 6767
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-gamarr-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/gamarr/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 8103

          persistence:
            config:
              size: 2Gi
              accessMode: ReadWriteOnce
              advancedMounts:
                main:
                  main:
                    - path: /config
            media:
              existingClaim: media-pvc
              advancedMounts:
                main:
                  main:
                    - path: /downloads
                    - path: /media
                  init-library:
                    - path: /media
    '';
    path = "/var/lib/rancher/k3s/server/manifests/gamarr.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
