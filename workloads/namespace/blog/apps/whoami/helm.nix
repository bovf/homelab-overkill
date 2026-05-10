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
          # Keel watches this Deployment for new digests under :latest and
          # triggers a rolling update when CI republishes the image.
          # Polled every 1 minute.
          #
          # match-tag: "true" pins Keel to the *current* tag (`latest`).
          # Without it Keel picks "newer-looking" sibling tags in the registry
          # (e.g. it would silently rewrite tag → 7c5a45fe and never update
          # again). With it, Keel only triggers when :latest's digest changes.
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
                    # External URL — the in-cluster registry service hostname
                    # can't be resolved by the kubelet (pulls happen at host
                    # level, before cluster DNS), and port 5000 is plain HTTP.
                    # Using the external hostname costs a small bit of egress
                    # but avoids a node-level k3s registries.yaml + extraHosts
                    # + insecure_skip_verify dance. Worth revisiting if the
                    # blog ever ships large images.
                    # Requires the GitLab project's Container Registry visibility
                    # to be set to Public so kubelet + Keel can pull anonymously.
                    repository: registry.dobryops.com/bovf/whoami-blog
                    tag: latest
                    # Always re-pull so a fresh digest under :latest replaces
                    # the running image once Keel triggers a rollout.
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
