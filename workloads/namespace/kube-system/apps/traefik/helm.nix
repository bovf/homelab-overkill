{...}: {
  services.k3s.manifests.traefik-config.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChartConfig";
    metadata = {
      name = "traefik";
      namespace = "kube-system";
    };
    spec = {
      valuesContent = ''
        image:
          registry: docker.io
          repository: rancher/mirrored-library-traefik
          tag: "3.7.7"

        ports:
          web:
            port: 8000
            expose:
              default: true
            exposedPort: 80
            protocol: TCP
          websecure:
            port: 8443
            expose:
              default: true
            exposedPort: 443
            protocol: TCP

        # Pin traefik at the bottom of the MetalLB pool so per-service
        # `-lan` Services can claim IPs further into the range.
        service:
          type: LoadBalancer
          annotations:
            metallb.io/loadBalancerIPs: 192.168.2.1

        # `insecure: true` exposes dashboard+api on :8080 without auth.
        # Required for the pangolin-kwg path that DNATs directly to the
        # pod, bypassing any IngressRoute Host-routing. Pangolin SSO
        # sits in front.
        api:
          dashboard: true
          insecure: true

        providers:
          kubernetesIngress:
            publishedService:
              enabled: true
          kubernetesCRD:
            allowCrossNamespace: true

        experimental:
          kubernetesGateway:
            enabled: false

        metrics:
          prometheus:
            addEntryPointsLabels: true
            addRoutersLabels: true
            addServicesLabels: true
            entryPoint: metrics
            service:
              enabled: true
            serviceMonitor:
              enabled: true
              namespace: monitoring
              interval: 30s

        # cert-manager-issued *.dobryops.com wildcard cert. Every TLS
        # request that doesn't match a more-specific cert lands here.
        # See certificate.nix for the Certificate CR.
        tlsStore:
          default:
            defaultCertificate:
              secretName: wildcard-dobryops-com-tls

        additionalArguments:
          - "--log.level=INFO"
      '';
    };
  };
}
