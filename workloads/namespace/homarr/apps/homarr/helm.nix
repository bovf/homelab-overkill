{ config, ... }:

{
  sops.templates."helm/homarr.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: homarr
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: homarr
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              # Roll the pod when AUTH_SECRET / BASE_URL change.
              secret.reloader.stakater.com/reload: "homarr-env"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: ghcr.io/homarr-labs/homarr
                    tag: "v1.62.0"
                  envFrom:
                    - secretRef:
                        name: homarr-env
                  env:
                    TZ: "Europe/Sofia"
                  # Homarr v1 binds :7575 from its own entrypoint — passing
                  # PORT / HOSTNAME triggers a second listener that collides
                  # with the first (EADDRINUSE). Defaults are correct.
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 7575
                        initialDelaySeconds: 30
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 3
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 7575
                        initialDelaySeconds: 15
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 100m
                      memory: 200Mi
                    limits:
                      cpu: 500m
                      memory: 1Gi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  # Unique tunnel-IP port — every kwg-routed service shares
                  # the 100.89.128.16 externalIP, so ports must not collide.
                  # 8088/8091/8092/8093 are taken; 8094 is next free.
                  port: 8094
                  targetPort: 7575
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/home/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            appdata:
              # SQLite database + uploaded icons / custom logos.
              accessMode: ReadWriteOnce
              size: 2Gi
              storageClass: local-path
              globalMounts:
                - path: /appdata
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/homarr.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
