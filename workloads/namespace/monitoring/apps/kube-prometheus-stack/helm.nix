{ config, ... }:

{
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
          # k3s embeds kube-controller-manager, kube-scheduler, and kube-proxy
          # inside the k3s server binary. The chart's separate ServiceMonitors
          # for them never find targets, producing permanent
          # KubeControllerManagerDown / KubeSchedulerDown / KubeProxyDown
          # false alerts. Disable them.
          kubeControllerManager:
            enabled: false
          kubeScheduler:
            enabled: false
          kubeProxy:
            enabled: false

          # Suppress chart-bundled alerts we don't want shipped at all:
          #   - Watchdog: dead-man's-switch heartbeat (we don't use one externally)
          #   - InfoInhibitor: meta-alert used by chart's inhibit_rules
          # Removing the rule is cleaner than routing-to-null; nothing fires,
          # nothing to ignore.
          defaultRules:
            disabled:
              Watchdog: true
              InfoInhibitor: true

          alertmanager:
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
              # Without this Alertmanager advertises its in-cluster service URL
              # in emails ("View in Alertmanager" link). Setting it here makes
              # the link in notifications resolve to the public hostname.
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
                # Scaffold receiver — kept even though nothing routes to it
                # right now, so the chart's auto-injected inhibit_rules /
                # any future alert routing has a black-hole sink available.
                - name: "null"
                - name: email-warnings
                  email_configs:
                    - to: dobry989@gmail.com
                      send_resolved: true
                      headers:
                        Subject: "[homelab] {{ .Status | toUpper }} {{ .GroupLabels.alertname }}"

          prometheus:
            prometheusSpec:
              enableFeatures:
                - otlp-write-receiver
              enableRemoteWriteReceiver: true
              # Discover ServiceMonitors / PodMonitors / PrometheusRules / Probes
              # from any namespace and any release, not just kube-prometheus-stack's
              # own. Required so Loki, version-checker, intel-gpu-exporter, etc.
              # are scraped without per-workload `release` labels.
              serviceMonitorSelectorNilUsesHelmValues: false
              podMonitorSelectorNilUsesHelmValues: false
              ruleSelectorNilUsesHelmValues: false
              probeSelectorNilUsesHelmValues: false
              scrapeConfigSelectorNilUsesHelmValues: false
          grafana:
            service:
              type: ClusterIP
              port: 32000
            admin:
              existingSecret: grafana-admin-password
              userKey: admin-user
              passwordKey: admin-password
            # Tell Grafana its external URL so share links / OAuth callbacks
            # / generated absolute URLs use the public hostname instead of
            # the in-cluster service:port.
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
    path  = "/var/lib/rancher/k3s/server/manifests/kube-prometheus-stack.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
