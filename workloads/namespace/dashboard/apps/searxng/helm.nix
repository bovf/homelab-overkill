{ config, ... }:

{
  sops.templates."helm/searxng.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: searxng
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: dashboard
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              configmap.reloader.stakater.com/reload: "searxng-settings"
              secret.reloader.stakater.com/reload:    "searxng-env"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: docker.io/searxng/searxng
                    tag: "2026.5.31-7159b8aed"
                    pullPolicy: IfNotPresent
                  envFrom:
                    - secretRef:
                        name: searxng-env
                  env:
                    TZ: "Europe/Sofia"
                    SEARXNG_BASE_URL: "https://${config.sops.placeholder."pangolin/resources/search/domain"}/"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /healthz
                          port: 8080
                        initialDelaySeconds: 30
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 3
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /healthz
                          port: 8080
                        initialDelaySeconds: 10
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 50m
                      memory: 128Mi
                    limits:
                      cpu: 500m
                      memory: 512Mi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  # 8097=uptime, 8099=speedtest, 8098 = searxng.
                  port: 8098
                  targetPort: 8080
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/search/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            settings:
              type: configMap
              name: searxng-settings
              globalMounts:
                - path: /etc/searxng/settings.yml
                  subPath: settings.yml
                  readOnly: true
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/searxng.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
