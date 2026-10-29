{config, ...}: {
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
        version: "4.6.2"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          controllers:
            main:
              containers:
                main:
                  image:
                    repository: sportarr/sportarr
                    # Pinned to digest (upstream publishes mutable stable/dev tags,
                    # so this keeps deploys reproducible).
                    # Bump by re-resolving with: docker buildx imagetools inspect sportarr/sportarr:4.1
                    tag: "4.1@sha256:5747ba701adac29fdf3c5139e4a9437c4b9d4f61ce8cddfe7a8b8194bd8fc46a"
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
                  port: 1867
                  protocol: TCP
          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-sportarr-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/sportarr/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 1867
          persistence:
            data:
              existingClaim: media-pvc
              globalMounts:
                - path: /data
            config:
              size: 2Gi
              accessMode: ReadWriteOnce
              globalMounts:
                - path: /config
    '';
    path = "/var/lib/rancher/k3s/server/manifests/sportarr.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
