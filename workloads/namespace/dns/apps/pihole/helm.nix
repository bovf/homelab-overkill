{ ... }:

{
  services.k3s.manifests.pihole-helm.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "pihole";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://mojo2600.github.io/pihole-kubernetes/";
      chart = "pihole";
      version = "2.14.0";
      targetNamespace = "dns";

      valuesContent = ''
        replicaCount: 1

        image:
          repository: pihole/pihole
          tag: "2024.12.2"
          pullPolicy: IfNotPresent

        strategy:
          type: RollingUpdate

        # ServiceType: Use LoadBalancer or NodePort for DNS access
        serviceType: LoadBalancer

        # Ingress for web interface
        ingress:
          enabled: true
          ingressClassName: traefik
          hosts:
            - pihole.your-domain.local
          tls:
            enabled: true
            certManager:
              enabled: true

        # Persistent storage for configuration and logs
        persistentVolumeClaim:
          enabled: true
          storageClassName: local-path
          accessMode: ReadWriteOnce
          size: 2Gi

        # DNS ports
        serviceTCP:
          loadBalancerIP: ~
          type: LoadBalancer
          port: 53

        serviceUDP:
          loadBalancerIP: ~
          type: LoadBalancer
          port: 53

        # Web interface
        webHttp:
          enabled: true
          port: 80

        webHttps:
          enabled: true
          port: 443

        # Resource limits
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 256Mi

        # Environment variables for Pi-hole configuration
        # These configure DNS behavior, logging, and retention
        env:
          - name: TZ
            value: "Europe/Sofia"
          - name: WEBPASSWORD
            valueFrom:
              secretKeyRef:
                name: pihole-secret
                key: WEBPASSWORD
          # Logging: set to 0 to disable, 1 to enable
          - name: QUERY_LOGGING
            value: "1"
          # Database retention: 7 days (in seconds: 604800)
          - name: MAXDBDAYS
            value: "7"

        # Pod security context
        podSecurityContext:
          fsGroup: 999
          runAsUser: 999
          runAsNonRoot: true

        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
              - NET_BIND_SERVICE  # Required for port 53
            drop:
              - ALL
          readOnlyRootFilesystem: false

        # Node selection (optional)
        nodeSelector: {}
        tolerations: []
        affinity: {}
      '';
    };
  };
}
