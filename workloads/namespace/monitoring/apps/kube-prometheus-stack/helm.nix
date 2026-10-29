{config, ...}: {
  sops.templates."helm/kube-prometheus-stack.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: kube-prometheus-stack
        namespace: kube-system
      spec:
        repo: https://prometheus-community.github.io/helm-charts
        chart: kube-prometheus-stack
        version: "86.2.3"
        targetNamespace: monitoring
        createNamespace: true
        valuesContent: |
          # k3s bundles these components into the server binary, so the
          # chart's ServiceMonitors find no targets and fire permanent
          # *Down alerts.
          kubeControllerManager:
            enabled: false
          kubeScheduler:
            enabled: false
          kubeProxy:
            enabled: false

          defaultRules:
            disabled:
              Watchdog: true
              InfoInhibitor: true

          prometheusOperator:
            admissionWebhooks:
              # Avoid k3s HelmChart pre/post-upgrade hook timeouts. The
              # validating webhook is useful guardrail, but not required for
              # this single-node homelab and currently blocks chart/image
              # upgrades from rolling out.
              enabled: false

          alertmanager:
            service:
              type: ClusterIP
              # Tunnel-side ingress on a sibling Service (external-services.nix);
              # attaching externalIPs here would also claim the
              # config-reloader's :8080 and collide with qbittorrent.
            ingress:
              enabled: true
              ingressClassName: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.middlewares: monitoring-alertmanager-headers@kubernetescrd
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              path: /
              pathType: Prefix
              hosts:
                - ${config.sops.placeholder."pangolin/resources/alertmanager/domain"}
            alertmanagerSpec:
              image:
                tag: v0.34.2
                sha: 39d8bb3966c694a124428a3a88fbcffd40bd069129ecd47c059f8a3f17c55f3b
              # Makes the "View in Alertmanager" link in emails public.
              externalUrl: "https://${config.sops.placeholder."pangolin/resources/alertmanager/domain"}"
            config:
              global:
                smtp_smarthost: "smtp.gmail.com:587"
                smtp_from: "dobry989@gmail.com"
                smtp_auth_username: "dobry989@gmail.com"
                smtp_auth_password: "${config.sops.placeholder."monitoring/alertmanager/smtp_password"}"
                smtp_require_tls: true
              route:
                group_by: ["alertname", "namespace"]
                group_wait: 30s
                group_interval: 5m
                repeat_interval: 24h
                receiver: email-warnings
              receivers:
                # Black-hole sink for the chart's auto-injected inhibit_rules.
                - name: "null"
                - name: email-warnings
                  email_configs:
                    - to: dobry989@gmail.com
                      send_resolved: true
                      headers:
                        Subject: "[homelab] {{ .Status | toUpper }} {{ .GroupLabels.alertname }}"

          prometheus:
            service:
              type: ClusterIP
              # Tunnel-side ingress on a sibling Service — see alertmanager above.
            ingress:
              enabled: true
              ingressClassName: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.middlewares: monitoring-prometheus-headers@kubernetescrd
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              path: /
              pathType: Prefix
              hosts:
                - ${config.sops.placeholder."pangolin/resources/prometheus/domain"}
            prometheusSpec:
              image:
                tag: v3.15.1
                sha: fa3302279710be2f21a8301ec17a8b4f2301fd829bd113839b3b6b02b6f191a2
              # Makes Prometheus generate public absolute links behind Traefik/Pangolin.
              externalUrl: "https://${config.sops.placeholder."pangolin/resources/prometheus/domain"}"
              enableFeatures:
                - otlp-write-receiver
              enableRemoteWriteReceiver: true
              # Discover monitors from any namespace/release, not just this chart's.
              serviceMonitorSelectorNilUsesHelmValues: false
              podMonitorSelectorNilUsesHelmValues: false
              ruleSelectorNilUsesHelmValues: false
              probeSelectorNilUsesHelmValues: false
              scrapeConfigSelectorNilUsesHelmValues: false
          kube-state-metrics:
            image:
              tag: v2.20.0

          prometheus-node-exporter:
            image:
              tag: v1.12.1
              digest: sha256:1b4e4438faca4dd7e001dd445d161a4a2091b0fededa84093b3a8dfeae1f1be0
              distroless: false

          grafana:
            # First enablement creates an empty PVC; back up the old pod first.
            persistence:
              enabled: true
              type: pvc
              storageClassName: local-path
              accessModes: [ReadWriteOnce]
              size: 10Gi
            deploymentStrategy:
              type: Recreate
            image:
              tag: "13.3.0"
              sha: 488984b716c0862639f91a698adbe2862677a5a07bad42da5f03f3030883b205
            sidecar:
              image:
                tag: 2.14.1
                sha: 092dbe0c335fba9af414a27630ca68f34df6185784fa847d9954187e69dbfdd7
            service:
              type: ClusterIP
              port: 32000
              externalIPs:
                - "100.89.128.16"
            admin:
              existingSecret: grafana-admin-password
              userKey: admin-user
              passwordKey: admin-password
            # Point Grafana at the sibling grafana-image-renderer Service
            # so `/render/...` URLs return PNGs at a fixed desktop viewport
            # (defeats responsive single-column stacking for iOS widgets).
            # RENDERER_TOKEN must be any non-default string or Grafana 10+
            # refuses to start. Renderer side doesn't enforce AUTH_TOKEN,
            # both endpoints are ClusterIP-only.
            env:
              GF_RENDERING_SERVER_URL: "http://grafana-image-renderer.monitoring.svc.cluster.local:8081/render"
              GF_RENDERING_CALLBACK_URL: "http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:32000/"
              GF_RENDERING_RENDERER_TOKEN: "${config.sops.placeholder."monitoring/grafana/renderer_token"}"
            # External URL for share links / OAuth callbacks.
            grafana.ini:
              server:
                root_url: "https://${config.sops.placeholder."pangolin/resources/grafana/domain"}"
                serve_from_sub_path: false
                domain: "${config.sops.placeholder."pangolin/resources/grafana/domain"}"
            ingress:
              enabled: true
              ingressClassName: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.middlewares: monitoring-grafana-headers@kubernetescrd
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              path: /
              pathType: Prefix
              hosts:
                - ${config.sops.placeholder."pangolin/resources/grafana/domain"}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/kube-prometheus-stack.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
