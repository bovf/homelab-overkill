{ config, ... }:

{
  sops.templates."helm/sonarr.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: sonarr
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
                    repository: ghcr.io/linuxserver/sonarr
                    tag: 4.0.17
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
                  port: 8989
                  protocol: TCP
          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-sonarr-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/sonarr/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 8989
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
    path  = "/var/lib/rancher/k3s/server/manifests/sonarr.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
