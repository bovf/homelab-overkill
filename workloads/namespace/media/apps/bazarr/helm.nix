{ ... }:

{
  # Bazarr deployment
  services.k3s.manifests.bazarr.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "bazarr";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://bjw-s-labs.github.io/helm-charts";
      chart = "app-template";
      version = "2.4.0";
      targetNamespace = "media";
      createNamespace = false;
      valuesContent = ''
        controllers:
          main:
            containers:
              main:
                image:
                  repository: ghcr.io/linuxserver/bazarr
                  tag: 1.5.3
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
                port: 6767
                targetPort: 6767
                protocol: TCP
        ingress:
          main:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              traefik.ingress.kubernetes.io/router.middlewares: "media-bazarr-headers@kubernetescrd"
            hosts:
              - host: bazarr.dobryops.com
                paths:
                  - path: /
                    pathType: Prefix
                    service:
                      name: main
                      port: 6767
        persistence:
          config:
            enabled: true
            mountPath: /config
            size: 2Gi
            accessMode: ReadWriteOnce
          media:
            enabled: true
            mountPath: /media
            existingClaim: media-pvc
      '';
    };
  };
}
