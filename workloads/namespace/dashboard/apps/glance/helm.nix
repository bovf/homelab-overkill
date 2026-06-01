{ config, ... }:

{
  sops.templates."helm/glance.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: glance
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
              # Roll on glance.yml changes (it's mounted from the Secret
              # below) and on the GitLab token secret churning.
              secret.reloader.stakater.com/reload: "glance-config,glance-env"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: glanceapp/glance
                    tag: "v0.8.5"
                    pullPolicy: IfNotPresent
                  envFrom:
                    - secretRef:
                        name: glance-env
                  env:
                    TZ: "Europe/Sofia"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
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
                          path: /
                          port: 8080
                        initialDelaySeconds: 10
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 50m
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
                  # 8097=uptime, 8098=searxng, 8099=speedtest, 8100=glance.
                  port: 8100
                  targetPort: 8080
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/glance/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            config:
              type: secret
              name: glance-config
              globalMounts:
                - path: /app/config/glance.yml
                  subPath: glance.yml
                  readOnly: true
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/glance.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  # GitLab read token for the nixpkgs-drift widgets — injected as env var
  # so glance.yml can interpolate `${GITLAB_TOKEN}` without baking the
  # plaintext into the rendered config Secret.
  sops.templates."glance/env.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: glance-env
        namespace: dashboard
      type: Opaque
      stringData:
        GITLAB_TOKEN: "${config.sops.placeholder."gitlab/glance_read_token"}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/glance-env.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
