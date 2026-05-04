{ config, ... }:

{
  sops.templates."helm/pihole.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: pihole
        namespace: kube-system
      spec:
        repo: https://mojo2600.github.io/pihole-kubernetes/
        chart: pihole
        version: "2.31.0"
        targetNamespace: dns
        createNamespace: false
        valuesContent: |
          replicaCount: 1

          image:
            repository: pihole/pihole
            tag: "2025.02.2"
            pullPolicy: IfNotPresent

          strategy:
            type: RollingUpdate

          serviceType: ClusterIP

          ingress:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              traefik.ingress.kubernetes.io/router.middlewares: dns-pihole-headers@kubernetescrd
            hosts:
              - ${config.sops.placeholder."pangolin/resources/pihole/domain"}
            tls: false

          persistentVolumeClaim:
            enabled: true
            storageClassName: local-path
            accessMode: ReadWriteOnce
            size: 2Gi

          serviceDns:
            # Two separate Services (TCP + UDP). klipper-lb handles single-protocol
            # Services more reliably than mixedService=true, which silently skipped
            # creating the svclb pod and left the LAN IP unbound.
            mixedService: false
            type: LoadBalancer
            loadBalancerIP: 192.0.2.10
            # Cluster (not Local) so off-subnet clients get correct return routing
            # via SNAT. Loses real client IP in pi-hole's query log for those, but
            # that's a fair trade for this homelab.
            externalTrafficPolicy: Cluster

          serviceDhcp:
            enabled: false

          webHttp: "80"
          webHttps: "443"

          resources:
            limits:
              cpu: 500m
              memory: 512Mi
            requests:
              cpu: 100m
              memory: 256Mi

          admin:
            existingSecret: pihole-web-password
            passwordKey: password

          env:
            - name: TZ
              value: "Europe/Sofia"
            - name: FTLCONF_dns_upstreams
              value: "8.8.8.8;8.8.4.4"
            - name: FTLCONF_query_logging
              value: "true"
            - name: FTLCONF_database_maxdbdays
              value: "7"

          podDnsConfig:
            enabled: true
            policy: "None"
            nameservers:
              - 8.8.8.8
              - 8.8.4.4

          podSecurityContext:
            fsGroup: 999
            runAsUser: 999
            runAsNonRoot: true

          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              add:
                - NET_BIND_SERVICE
              drop:
                - ALL
            readOnlyRootFilesystem: false

          nodeSelector: {}
          tolerations: []
          affinity: {}
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/pihole.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
