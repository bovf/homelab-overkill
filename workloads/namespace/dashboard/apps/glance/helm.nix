{config, ...}: {
  services.k3s.manifests.glance-icons.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "glance-icons";
      namespace = "dashboard";
    };
    data = {
      "ezbookkeeping.svg" = builtins.readFile ./icons/ezbookkeeping.svg;
      "blog.svg" = builtins.readFile ./icons/blog.svg;
      "pangolin.svg" = builtins.readFile ./icons/pangolin.svg;
    };
  };

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
              configmap.reloader.stakater.com/reload: "glance-icons"

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
                traefik.ingress.kubernetes.io/router.middlewares: dashboard-glance-headers@kubernetescrd
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
            icons:
              type: configMap
              name: glance-icons
              globalMounts:
                - path: /app/custom-assets/icons
                  readOnly: true
    '';
    path = "/var/lib/rancher/k3s/server/manifests/glance.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };

  # Env-injected secrets for the dashboard's API integrations. Kept out
  # of glance-config so we don't have to re-render the whole 600-line
  # YAML when a single key rotates.
  sops.templates."glance/env.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: glance-env
        namespace: dashboard
      type: Opaque
      stringData:
        GITLAB_TOKEN:    "${config.sops.placeholder."gitlab/glance_read_token"}"
        SONARR_KEY:      "${config.sops.placeholder."media/sonarr/api_key"}"
        RADARR_KEY:      "${config.sops.placeholder."media/radarr/api_key"}"
        PROWLARR_KEY:    "${config.sops.placeholder."media/prowlarr/api_key"}"
        BAZARR_KEY:      "${config.sops.placeholder."media/bazarr/api_key"}"
        JELLYSEERR_KEY:  "${config.sops.placeholder."media/jellyseerr/api_key"}"
        JELLYFIN_KEY:    "${config.sops.placeholder."homarr/integrations/jellyfin_key"}"
        # Seeded by speedtest-tracker-api-token-job.nix. Laravel Sanctum
        # bearer tokens are `<token-id>|<plain token>`; the job stores the
        # SHA-256 of APP_KEY as token id 9002 with results:read scope.
        SPEEDTEST_TOKEN: "9002|${config.sops.placeholder."speedtest/app_key"}"
    '';
    path = "/var/lib/rancher/k3s/server/manifests/glance-env.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
