{ config, ... }:

{
  sops.templates."helm/jellyseerr.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: jellyseerr
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "2.4.0"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            securityContext:
              runAsUser: 1000
              runAsGroup: 1000
              fsGroup: 1000
              fsGroupChangePolicy: OnRootMismatch
          controllers:
            main:
              containers:
                main:
                  image:
                    repository: seerr/seerr
                    tag: v3.2.0
                  env:
                    TZ: "Europe/Helsinki"
                    LOG_LEVEL: "info"
          service:
            main:
              enabled: true
              type: ClusterIP
              ports:
                http:
                  port: 5055
                  targetPort: 5055
                  protocol: TCP
          ingress:
            main:
              enabled: true
              ingressClassName: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-jellyseerr-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/jellyseerr/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        name: main
                        port: 5055
          persistence:
            config:
              enabled: true
              size: 2Gi
              accessMode: ReadWriteOnce
              globalMounts:
                - path: /app/config
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/jellyseerr.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
