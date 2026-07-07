{...}: {
  sops.templates."helm/alloy.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: alloy
        namespace: kube-system
      spec:
        repo: https://grafana.github.io/helm-charts
        chart: alloy
        version: "1.10.0"
        targetNamespace: monitoring
        createNamespace: false
        valuesContent: |
          crds:
            create: true

          controller:
            type: daemonset

          image:
            tag: v1.17.1

          alloy:
            stabilityLevel: generally-available

            extraPorts:
              - name: otlp-grpc
                port: 4317
                targetPort: 4317
                protocol: TCP
              - name: otlp-http
                port: 4318
                targetPort: 4318
                protocol: TCP

            configMap:
              create: true
              content: |-
                // ----------------------------------------------------------------
                // Pod log scraping → Loki
                //
                // Reads container logs via the Kubernetes API rather than tailing
                // /var/log/pods. RBAC for pods + pods/log is in the chart's
                // default role. Single-node homelab — API-server load is fine.
                // ----------------------------------------------------------------
                discovery.kubernetes "pods" {
                  role = "pod"
                }

                // Promote __meta_kubernetes_* labels onto user-visible label names.
                // Loki drops any label with a __ prefix at write time.
                discovery.relabel "pods" {
                  targets = discovery.kubernetes.pods.targets

                  rule {
                    source_labels = ["__meta_kubernetes_namespace"]
                    target_label  = "namespace"
                  }
                  rule {
                    source_labels = ["__meta_kubernetes_pod_name"]
                    target_label  = "pod"
                  }
                  rule {
                    source_labels = ["__meta_kubernetes_pod_container_name"]
                    target_label  = "container"
                  }
                  rule {
                    source_labels = ["__meta_kubernetes_pod_node_name"]
                    target_label  = "node"
                  }
                  rule {
                    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
                    target_label  = "app"
                  }
                }

                loki.source.kubernetes "pods" {
                  targets    = discovery.relabel.pods.output
                  forward_to = [loki.write.default.receiver]
                }

                loki.write "default" {
                  endpoint {
                    url = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
                  }
                }

                // ----------------------------------------------------------------
                // OTLP receiver (gRPC :4317, HTTP :4318)
                //
                // Apps that emit OpenTelemetry signals push to
                //   alloy.monitoring.svc.cluster.local:4318
                // and Alloy fans out: metrics → Prometheus OTLP receiver,
                // logs → Loki OTLP endpoint. Traces are dropped until Tempo
                // lands.
                // ----------------------------------------------------------------
                otelcol.receiver.otlp "ingest" {
                  grpc {
                    endpoint = "0.0.0.0:4317"
                  }
                  http {
                    endpoint = "0.0.0.0:4318"
                  }
                  output {
                    metrics = [otelcol.processor.batch.default.input]
                    logs    = [otelcol.processor.batch.default.input]
                  }
                }

                otelcol.processor.batch "default" {
                  output {
                    metrics = [otelcol.exporter.otlphttp.prometheus.input]
                    logs    = [otelcol.exporter.otlphttp.loki.input]
                  }
                }

                otelcol.exporter.otlphttp "prometheus" {
                  client {
                    endpoint = "http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090/api/v1/otlp"
                    tls {
                      insecure = true
                    }
                  }
                }

                otelcol.exporter.otlphttp "loki" {
                  client {
                    endpoint = "http://loki.monitoring.svc.cluster.local:3100/otlp"
                    tls {
                      insecure = true
                    }
                  }
                }

            resources:
              requests:
                cpu: 100m
                memory: 256Mi
              limits:
                memory: 512Mi

          rbac:
            create: true

          serviceAccount:
            create: true

          service:
            enabled: true
            type: ClusterIP

          serviceMonitor:
            enabled: true
    '';
    path = "/var/lib/rancher/k3s/server/manifests/alloy.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
