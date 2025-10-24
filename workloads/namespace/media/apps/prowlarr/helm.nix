{ ... }:

{
  # Prowlarr deployment
  services.k3s.manifests.prowlarr.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "prowlarr";
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
                  repository: ghcr.io/linuxserver/prowlarr
                  tag: 2.0.5
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
                port: 9696
                targetPort: 9696
                protocol: TCP
        ingress:
          main:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
              traefik.ingress.kubernetes.io/router.middlewares: "media-prowlarr-headers@kubernetescrd"
            hosts:
              - host: prowlarr.dobryops.com
                paths:
                  - path: /
                    pathType: Prefix
                    service:
                      name: main
                      port: 9696
        persistence:
          config:
            enabled: true
            mountPath: /config
            size: 2Gi
            accessMode: ReadWriteOnce
      '';
    };
  };
}
