{config, ...}: {
  sops.templates."helm/element.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: element
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
              configmap.reloader.stakater.com/reload: "element-config"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: ghcr.io/element-hq/element-web
                    tag: "v1.12.21"
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
                  # Unique tunnel-IP port — every kwg-routed service shares
                  # the 100.89.128.16 externalIP, so ports must not collide.
                  port: 8091
                  targetPort: 80
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: matrix-element-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/element/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            config:
              type: configMap
              name: element-config
              globalMounts:
                - path: /app/config.json
                  subPath: config.json
                  readOnly: true
    '';
    path = "/var/lib/rancher/k3s/server/manifests/element.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
