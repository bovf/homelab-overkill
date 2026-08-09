{config, ...}: {
  sops.templates."helm/loki.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: loki
        namespace: kube-system
      spec:
        repo: https://grafana.github.io/helm-charts
        chart: loki
        version: "7.0.0"
        targetNamespace: monitoring
        createNamespace: false
        valuesContent: |
          deploymentMode: SingleBinary

          loki:
            image:
              tag: 3.7.6@sha256:efd47c67f9bac88ca29bcf8cb997d9ab29d1848bd0aff579282295542a745952
            auth_enabled: false
            commonConfig:
              replication_factor: 1
            schemaConfig:
              configs:
                - from: "2024-04-01"
                  store: tsdb
                  object_store: s3
                  schema: v13
                  index:
                    prefix: index_
                    period: 24h
            storage:
              type: s3
              bucketNames:
                chunks: loki-chunks
                ruler: loki-chunks
                admin: loki-chunks
              s3:
                endpoint: minio.database.svc.cluster.local:9000
                s3ForcePathStyle: true
                insecure: true
                accessKeyId: ${config.sops.placeholder."database/minio/loki/access_key"}
                secretAccessKey: ${config.sops.placeholder."database/minio/loki/secret_key"}
            limits_config:
              retention_period: 720h
              ingestion_rate_mb: 10
              ingestion_burst_size_mb: 20
              reject_old_samples: true
              reject_old_samples_max_age: 168h
              allow_structured_metadata: true
              volume_enabled: true
            ingester:
              chunk_idle_period: 30m
              chunk_target_size: 1572864
              chunk_retain_period: 30s

          sidecar:
            image:
              tag: 2.10.1@sha256:7eac5c4fed714a18d038fc9fea57d8744d113367935dac0ea4eb6a87cef704a3

          singleBinary:
            replicas: 1
            persistence:
              enabled: true
              size: 10Gi
              storageClass: local-path
            resources:
              requests:
                cpu: 100m
                memory: 256Mi
              limits:
                memory: 1Gi

          backend:
            replicas: 0
          read:
            replicas: 0
          write:
            replicas: 0

          chunksCache:
            enabled: false
          resultsCache:
            enabled: false

          gateway:
            enabled: false

          minio:
            enabled: false

          lokiCanary:
            enabled: false
          test:
            enabled: false

          monitoring:
            serviceMonitor:
              enabled: true
              metricsInstance:
                enabled: false
            selfMonitoring:
              enabled: false
              grafanaAgent:
                installOperator: false
            dashboards:
              enabled: false
            rules:
              enabled: false
    '';
    path = "/var/lib/rancher/k3s/server/manifests/loki.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
