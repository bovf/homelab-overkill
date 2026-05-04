{ config, ... }:

{
  sops.templates."helm/bazarr.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: bazarr
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
                    repository: ghcr.io/linuxserver/bazarr
                    tag: 1.5.6
                  env:
                    TZ: "Europe/Helsinki"
                    PUID: "1000"
                    PGID: "1000"
          service:
            main:
              controller: main
              type: ClusterIP
              ports:
                http:
                  port: 6767
                  protocol: TCP
          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-bazarr-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/bazarr/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 6767
          persistence:
            config:
              size: 2Gi
              accessMode: ReadWriteOnce
              globalMounts:
                - path: /config
            media:
              existingClaim: media-pvc
              globalMounts:
                - path: /media
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/bazarr.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
