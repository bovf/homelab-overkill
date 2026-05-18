{ config, ... }:

{
  sops.templates."helm/minio.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: minio
        namespace: kube-system
      spec:
        repo: https://charts.min.io/
        chart: minio
        version: "5.3.0"
        targetNamespace: database
        createNamespace: false
        valuesContent: |
          image:
            repository: quay.io/minio/minio
            tag: latest
            pullPolicy: IfNotPresent

          mode: standalone

          existingSecret: minio-credentials

          persistence:
            enabled: true
            size: 50Gi
            storageClass: local-path

          resources:
            requests:
              memory: 512Mi
              cpu: 250m
            limits:
              memory: 2Gi
              cpu: 1000m

          service:
            type: ClusterIP
            port: 9000
            # Tunnel-side ingress for pangolin-kwg. S3 API at
            # 100.89.128.16:9000 → kube-proxy externalIPs → minio pod.
            externalIPs:
              - "100.89.128.16"

          consoleService:
            type: ClusterIP
            port: 9001
            # Same pattern for the console (port 9001).
            externalIPs:
              - "100.89.128.16"

          ingress:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              traefik.ingress.kubernetes.io/router.middlewares: database-minio-headers@kubernetescrd
            hosts:
              - ${config.sops.placeholder."pangolin/resources/minio/domain"}
            path: /
            pathType: Prefix

          consoleIngress:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              traefik.ingress.kubernetes.io/router.middlewares: database-minio-console-headers@kubernetescrd
            hosts:
              - ${config.sops.placeholder."pangolin/resources/minio_console/domain"}
            path: /
            pathType: Prefix
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/minio.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
