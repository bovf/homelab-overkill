{ ... }:

{
  sops.templates."helm/version-checker.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: version-checker
        namespace: kube-system
      spec:
        repo: https://charts.jetstack.io
        chart: version-checker
        version: "v0.10.0"
        targetNamespace: monitoring
        createNamespace: false
        valuesContent: |
          versionChecker:
            imageCacheTimeout: 30m
            logLevel: info
            # Scan every container in the cluster. Opt-out per pod with
            # annotation `enable.version-checker.io: "false"`.
            testAllContainers: true

          # Chart's ServiceMonitor doesn't expose metricRelabelings, and the
          # version-checker labels (namespace/pod/container of the WATCHED
          # workload) collide with Prometheus's own scrape-target labels
          # (the version-checker pod itself). We ship a custom ServiceMonitor
          # in ./servicemonitor.nix that fixes this.
          serviceMonitor:
            enabled: false

          # Built-in dashboard requires Grafana Operator; we ship our own
          # ConfigMap-based dashboard separately.
          dashboards:
            enabled: false

          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 500m
              memory: 256Mi
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/version-checker.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
