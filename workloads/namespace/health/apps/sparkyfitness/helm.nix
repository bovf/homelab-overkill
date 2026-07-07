{config, ...}: {
  sops.templates."helm/sparkyfitness.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: sparkyfitness
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: health
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              secret.reloader.stakater.com/reload: "sparkyfitness-secrets"

          controllers:
            main:
              containers:
                server:
                  image:
                    repository: docker.io/codewithcj/sparkyfitness_server
                    tag: "latest"
                  envFrom:
                    - secretRef:
                        name: sparkyfitness-secrets
                  env:
                    SPARKY_FITNESS_LOG_LEVEL: "info"
                    SPARKY_FITNESS_DB_USER: "sparky"
                    SPARKY_FITNESS_DB_HOST: "postgresql.database.svc.cluster.local"
                    SPARKY_FITNESS_DB_NAME: "sparkyfitness"
                    SPARKY_FITNESS_DB_PORT: "5432"
                    SPARKY_FITNESS_APP_DB_USER: "sparkyapp"
                    SPARKY_FITNESS_FRONTEND_URL: "https://${config.sops.placeholder."pangolin/resources/sparkyfitness/domain"}"
                    SPARKY_FITNESS_DISABLE_SIGNUP: "false"
                    SPARKY_FITNESS_ADMIN_EMAIL: "${config.sops.placeholder."admin/email"}"
                    ALLOW_PRIVATE_NETWORK_CORS: "false"
                    GARMIN_MICROSERVICE_URL: ""
                    PUID: "1000"
                    GUID: "1000"
                  resources:
                    requests:
                      cpu: 100m
                      memory: 256Mi
                    limits:
                      cpu: 1000m
                      memory: 1Gi
                frontend:
                  image:
                    repository: docker.io/codewithcj/sparkyfitness
                    tag: "latest"
                  env:
                    SPARKY_FITNESS_FRONTEND_URL: "https://${config.sops.placeholder."pangolin/resources/sparkyfitness/domain"}"
                    SPARKY_FITNESS_SERVER_HOST: "127.0.0.1"
                    SPARKY_FITNESS_SERVER_PORT: "3010"
                    NGINX_LISTEN_PORT: "8080"
                    PUID: "1000"
                    GUID: "1000"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 8080
                        initialDelaySeconds: 20
                        periodSeconds: 30
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 8080
                        initialDelaySeconds: 10
                        periodSeconds: 10
                  resources:
                    requests:
                      cpu: 20m
                      memory: 64Mi
                    limits:
                      cpu: 500m
                      memory: 256Mi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 8104
                  targetPort: 8080
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: health-sparkyfitness-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/sparkyfitness/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            uploads:
              size: 5Gi
              accessMode: ReadWriteOnce
              storageClass: local-path
              advancedMounts:
                main:
                  server:
                    - path: /app/SparkyFitnessServer/uploads
            backups:
              size: 2Gi
              accessMode: ReadWriteOnce
              storageClass: local-path
              advancedMounts:
                main:
                  server:
                    - path: /app/SparkyFitnessServer/backup
    '';
    path = "/var/lib/rancher/k3s/server/manifests/sparkyfitness.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
