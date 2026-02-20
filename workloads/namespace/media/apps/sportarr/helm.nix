{ config, ... }:

{
  sops.templates."helm/sportarr.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: sportarr
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "2.4.0"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          controllers:
            main:
              containers:
                main:
                  image:
                    repository: sportarr/sportarr
                    tag: latest
                  env:
                    TZ: "Europe/Helsinki"
                    PUID: "1000"
                    PGID: "1000"
          service:
            main:
              enabled: true
              type: ClusterIP
              ports:
                http:
                  port: 1867
                  targetPort: 1867
                  protocol: TCP
          ingress:
            main:
              enabled: true
              ingressClassName: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-sportarr-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/sportarr/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        name: main
                        port: 1867
          persistence:
            data:
              enabled: true
              mountPath: /data
              existingClaim: media-pvc
              subPath: sports
            config:
              enabled: true
              mountPath: /config
              size: 2Gi
              accessMode: ReadWriteOnce
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/sportarr.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
