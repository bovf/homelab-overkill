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
            testAllContainers: true

          # Chart's ServiceMonitor lacks metricRelabelings; the WATCHED
          # workload's labels collide with Prometheus's scrape-target
          # labels. Custom ServiceMonitor in ./servicemonitor.nix.
          serviceMonitor:
            enabled: false

          # Built-in dashboard requires Grafana Operator.
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
