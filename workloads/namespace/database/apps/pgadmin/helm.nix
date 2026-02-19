{ config, ... }:

{
  sops.templates."helm/pgadmin.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: pgadmin
        namespace: kube-system
      spec:
        repo: https://helm.runix.net
        chart: pgadmin4
        version: "1.50.0"
        targetNamespace: database
        createNamespace: false
        valuesContent: |
          image:
            registry: docker.io
            repository: dpage/pgadmin4
            tag: latest
            pullPolicy: IfNotPresent

          env:
            email: "${config.sops.placeholder."admin/email"}"
            password: ""
            existingSecret: pgadmin-credentials
            secretKeys:
              pgadminPasswordKey: password

          existingSecret: pgadmin-credentials

          persistentVolume:
            enabled: true
            size: 2Gi
            storageClass: local-path

          resources:
            requests:
              memory: 256Mi
              cpu: 100m
            limits:
              memory: 512Mi
              cpu: 500m

          service:
            type: ClusterIP
            port: 80

          ingress:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              traefik.ingress.kubernetes.io/router.middlewares: database-pgadmin-headers@kubernetescrd
            hosts:
              - host: ${config.sops.placeholder."pangolin/resources/pgadmin/domain"}
                paths:
                  - path: /
                    pathType: Prefix
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/pgadmin.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
