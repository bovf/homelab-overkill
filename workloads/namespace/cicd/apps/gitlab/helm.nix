{ ... }:

{
  services.k3s.manifests.gitlab.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "gitlab";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://charts.gitlab.io/";
      chart = "gitlab";
      version = "9.5.1";
      targetNamespace = "cicd";
      createNamespace = false;
      valuesContent = ''
        global:
          hosts:
            domain: dobryops.com
            gitlab:
              name: gitlab.dobryops.com
            registry:
              name: registry.dobryops.com
          
          ingress:
            enabled: true
            class: traefik
            configureCertmanager: false
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
          
          initialRootPassword:
            secret: gitlab-initial-root-password
            key: password
          
          # External PostgreSQL Configuration
          psql:
            host: postgresql.database.svc.cluster.local
            port: 5432
            username: gitlab
            database: gitlabhq_production
            password:
              secret: gitlab-postgres-secret
              key: password
          
          # Disable built-in MinIO
          minio:
            enabled: false
          
          # Configure external MinIO for object storage
          appConfig:
            object_store:
              enabled: true
              proxy_download: false
              connection:
                secret: gitlab-minio-connection
                key: connection
            
            lfs:
              enabled: true
              proxy_download: false
              bucket: gitlab-lfs
            artifacts:
              enabled: true
              proxy_download: false
              bucket: gitlab-artifacts
            uploads:
              enabled: true
              proxy_download: false
              bucket: gitlab-uploads
            packages:
              enabled: true
              proxy_download: false
              bucket: gitlab-packages
            externalDiffs:
              enabled: false
            
            terraformState:
              enabled: false
            
            ciSecureFiles:
              enabled: false
            
            dependencyProxy:
              enabled: false
        
        # Container Registry configuration with MinIO backend
        registry:
          enabled: true
          ingress:
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
              traefik.ingress.kubernetes.io/router.middlewares: "cicd-registry-headers@kubernetescrd"
          storage:
            secret: gitlab-registry-storage
            key: config
        
        # Disable components not needed
        installCertmanager: false

        nginx-ingress:
          enabled: false
        
        prometheus:
          install: false
        
        #To be configured
        gitlab-runner:
          install: false

        # Resource configuration for minimal installation
        gitlab:
          gitaly:
            resources:
              requests:
                cpu: 100m
                memory: 200Mi
              limits:
                cpu: 1
                memory: 2Gi
            persistence:
              size: 50Gi
          
          gitlab-shell:
            resources:
              requests:
                cpu: 50m
                memory: 50Mi
              limits:
                cpu: 200m
                memory: 256Mi
          
          gitlab-exporter:
            enabled: false
          
          webservice:
            minReplicas: 1
            maxReplicas: 1
            resources:
              requests:
                cpu: 300m
                memory: 1Gi
              limits:
                cpu: 1
                memory: 2.5Gi
          
          sidekiq:
            minReplicas: 1
            maxReplicas: 1
            resources:
              requests:
                cpu: 100m
                memory: 512Mi
              limits:
                cpu: 1
                memory: 2Gi
        
        postgresql:
          install: false
        
        redis:
          master:
            resources:
              requests:
                cpu: 100m
                memory: 128Mi
              limits:
                cpu: 500m
                memory: 512Mi
      '';
    };
  };
}
