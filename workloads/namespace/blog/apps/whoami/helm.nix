{ config, ... }:

{
  sops.templates."helm/whoami.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: whoami
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: blog
        createNamespace: false
        valuesContent: |
          # match-tag pins Keel to the running tag (:latest). Without it,
          # Keel picks "newer-looking" sibling tags from the registry.
          controllers:
            main:
              annotations:
                keel.sh/policy: "force"
                keel.sh/match-tag: "true"
                keel.sh/trigger: "poll"
                keel.sh/pollSchedule: "@every 1m"
              containers:
                main:
                  image:
                    # External URL — kubelet pulls happen before cluster DNS,
                    # so the in-cluster registry hostname isn't resolvable.
                    # GitLab Container Registry must be set to Public.
                    repository: registry.dobryops.com/bovf/whoami-blog
                    tag: latest
                    pullPolicy: Always
                  resources:
                    requests:
                      cpu: 10m
                      memory: 32Mi
                    limits:
                      cpu: 200m
                      memory: 128Mi
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 80
                        initialDelaySeconds: 5
                        periodSeconds: 30
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 80
                        initialDelaySeconds: 2
                        periodSeconds: 10

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
                traefik.ingress.kubernetes.io/router.middlewares: blog-whoami-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/whoami/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/whoami.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
