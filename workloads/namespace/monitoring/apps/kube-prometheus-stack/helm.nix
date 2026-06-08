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
        version: "84.5.0"
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
          grafana:
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
