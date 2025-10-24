{ ... }:

{
  services.k3s.manifests.pgadmin.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "pgadmin";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://helm.runix.net";
      chart = "pgadmin4";
      version = "1.50.0";
      targetNamespace = "database";
      createNamespace = false;
      valuesContent = ''
        image:
          registry: docker.io
          repository: dpage/pgadmin4
          tag: latest
          pullPolicy: IfNotPresent
        
        env:
          email: "dobry@dobryops.com"
          password: ""
          existingSecret: pgadmin-credentials
          secretKeys:
            pgadminPasswordKey: password
        
        existingSecret: pgadmin-credentials
        
        persistentVolume:
          enabled: true
          size: 2Gi
          storageClass: local-path
        
        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 512Mi
            cpu: 500m
        
        service:
          type: ClusterIP
          port: 80
        
        ingress:
          enabled: true
          ingressClassName: traefik
          annotations:
            traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
            traefik.ingress.kubernetes.io/router.middlewares: database-pgadmin-headers@kubernetescrd
          hosts:
            - host: pgadmin.dobryops.com
              paths:
                - path: /
                  pathType: Prefix
      '';
    };
  };
}
