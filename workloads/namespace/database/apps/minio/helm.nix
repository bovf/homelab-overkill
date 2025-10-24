{ ... }:

{
  services.k3s.manifests.minio.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "minio";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://charts.min.io/";
      chart = "minio";
      version = "5.3.0";
      targetNamespace = "database";
      createNamespace = false;
      valuesContent = ''
        image:
          repository: quay.io/minio/minio
          tag: latest
          pullPolicy: IfNotPresent
        
        mode: standalone
        
        existingSecret: minio-credentials
        
        persistence:
          enabled: true
          size: 50Gi
          storageClass: local-path
        
        resources:
          requests:
            memory: 512Mi
            cpu: 250m
          limits:
            memory: 2Gi
            cpu: 1000m
        
        service:
          type: ClusterIP
          port: 9000
        
        consoleService:
          type: ClusterIP
          port: 9001
        
        ingress:
          enabled: true
          ingressClassName: traefik
          annotations:
            traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
            traefik.ingress.kubernetes.io/router.middlewares: database-minio-headers@kubernetescrd
          hosts:
            - minio.dobryops.com
          path: /
          pathType: Prefix
        
        consoleIngress:
          enabled: true
          ingressClassName: traefik
          annotations:
            traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
            traefik.ingress.kubernetes.io/router.middlewares: database-minio-console-headers@kubernetescrd
          hosts:
            - minio-console.dobryops.com
          path: /
          pathType: Prefix
      '';
    };
  };
}
