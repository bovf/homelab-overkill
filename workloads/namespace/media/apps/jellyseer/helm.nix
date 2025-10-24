{ ... }:

{
  # Jellyseerr deployment
  services.k3s.manifests.jellyseerr.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "jellyseerr";
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
                  repository: fallenbagel/jellyseerr
                  tag: 2.7.3
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
              traefik.ingress.kubernetes.io/router.middlewares: "media-jellyseerr-headers@kubernetescrd"
            hosts:
              - host: jellyseerr.dobryops.com
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
    };
  };
}
