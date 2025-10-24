{ ... }:

{
  # Radarr deployment
  services.k3s.manifests.radarr.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "radarr";
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
                  repository: ghcr.io/linuxserver/radarr
                  tag: 5.27.5
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
                port: 7878
                targetPort: 7878
                protocol: TCP
        ingress:
          main:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
              traefik.ingress.kubernetes.io/router.middlewares: "media-radarr-headers@kubernetescrd"
            hosts:
              - host: radarr.dobryops.com
                paths:
                  - path: /
                    pathType: Prefix
                    service:
                      name: main
                      port: 7878
        persistence:
          downloads:
            enabled: true
            mountPath: /downloads
            existingClaim: media-pvc
            subPath: downloads
          config:
            enabled: true
            mountPath: /config
            size: 2Gi
            accessMode: ReadWriteOnce
      '';
    };
  };
}
