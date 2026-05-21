{ config, ... }:

{
  sops.templates."helm/synapse-admin.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: synapse-admin
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: matrix
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              configmap.reloader.stakater.com/reload: "synapse-admin-config"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: docker.io/awesometechnologies/synapse-admin
                    tag: "0.11.4"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 80
                        initialDelaySeconds: 10
                        periodSeconds: 30
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 80
                        initialDelaySeconds: 5
                        periodSeconds: 10
                  resources:
                    requests:
                      cpu: 10m
                      memory: 32Mi
                    limits:
                      cpu: 200m
                      memory: 128Mi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 80
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: matrix-synapse-admin-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/synapse_admin/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            config:
              type: configMap
              name: synapse-admin-config
              globalMounts:
                - path: /app/config.json
                  subPath: config.json
                  readOnly: true
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/synapse-admin.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
