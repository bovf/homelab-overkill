{config, ...}: {
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
        version: "4.6.2"
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
                    tag: "v3.4.1@sha256:f4768de5f616248d723e05891f3345a1402123775d03bf0890dbfedc0831bda1"
                  env:
                    TZ: "Europe/Helsinki"
                    LOG_LEVEL: "info"
          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 5055
                  protocol: TCP
          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-jellyseerr-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/jellyseerr/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 5055
          persistence:
            config:
              size: 2Gi
              accessMode: ReadWriteOnce
              globalMounts:
                - path: /app/config
    '';
    path = "/var/lib/rancher/k3s/server/manifests/jellyseerr.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
