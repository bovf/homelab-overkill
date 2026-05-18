{ config, ... }:

{
  sops.templates."helm/radarr.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: radarr
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          controllers:
            main:
              containers:
                main:
                  image:
                    repository: ghcr.io/linuxserver/radarr
                    tag: 6.1.1
                  env:
                    TZ: "Europe/Helsinki"
                    PUID: "1000"
                    PGID: "1000"
          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 7878
                  protocol: TCP
          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-radarr-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/radarr/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 7878
          persistence:
            downloads:
              existingClaim: media-pvc
              globalMounts:
                - path: /downloads
            config:
              size: 2Gi
              accessMode: ReadWriteOnce
              globalMounts:
                - path: /config
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/radarr.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
