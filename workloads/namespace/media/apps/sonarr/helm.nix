{ ... }:

{
  # Sonar deployment
  services.k3s.manifests.sonarr.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "sonarr";
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
                  repository: ghcr.io/linuxserver/sonarr
                  tag: 4.0.15
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
                port: 8989
                targetPort: 8989
                protocol: TCP
        ingress:
          main:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
              traefik.ingress.kubernetes.io/router.middlewares: "media-sonarr-headers@kubernetescrd"
            hosts:
              - host: sonarr.dobryops.com
                paths:
                  - path: /
                    pathType: Prefix
                    service:
                      name: main
                      port: 8989
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
