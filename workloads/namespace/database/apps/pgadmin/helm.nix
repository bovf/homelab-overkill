{config, ...}: {
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
        version: "1.64.0"
        targetNamespace: database
        createNamespace: false
        valuesContent: |
          image:
            registry: docker.io
            repository: dpage/pgadmin4
            tag: "2026-06-16-1"
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
            # Bumped from 80 to avoid the tunnel-side externalIPs port
            # collision (whoami/pgadmin/pihole-web/argocd all defaulted
            # to 80). targetPort defaults to the container's `http` port.
            port: 8088
            externalIPs:
              - "100.89.128.16"

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
    path = "/var/lib/rancher/k3s/server/manifests/pgadmin.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
