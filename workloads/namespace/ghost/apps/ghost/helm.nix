{ config, ... }:

{
  sops.templates."helm/ghost.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: ghost
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "3.5.1"
        targetNamespace: ghost
        createNamespace: false
        valuesContent: |
          controllers:
            main:
              containers:
                main:
                  image:
                    repository: ghost
                    tag: "6-alpine"
                    pullPolicy: IfNotPresent
                  env:
                    - name: url
                      value: https://${config.sops.placeholder."pangolin/resources/ghost/domain"}
                    - name: NODE_ENV
                      value: production
                    - name: database__client
                      value: sqlite3
                    - name: database__connection__filename
                      value: /var/lib/ghost/content/data/ghost.db
                    - name: database__useNullAsDefault
                      value: "true"
                    - name: database__debug
                      value: "false"
                  resources:
                    requests:
                      cpu: 100m
                      memory: 256Mi
                    limits:
                      cpu: 500m
                      memory: 512Mi

          service:
            main:
              controller: main
              type: ClusterIP
              ports:
                http:
                  port: 2368

          ingress:
            main:
              enabled: true
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: ghost-ghost-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/ghost/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            content:
              existingClaim: ghost-content
              globalMounts:
                - path: /var/lib/ghost/content

          podSecurityContext:
            fsGroup: 1000
            runAsUser: 1000
            runAsNonRoot: true
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/ghost.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  services.k3s.manifests.ghost-pvc.content = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = {
      name = "ghost-content";
      namespace = "ghost";
    };
    spec = {
      accessModes = [ "ReadWriteOnce" ];
      storageClassName = "local-path";
      resources.requests.storage = "8Gi";
    };
  };
}
