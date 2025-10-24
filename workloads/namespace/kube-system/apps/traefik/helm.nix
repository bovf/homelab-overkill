{ ... }:

{
  services.k3s.manifests.traefik-config.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChartConfig";
    metadata = {
      name = "traefik";
      namespace = "kube-system";
    };
    spec = {
      valuesContent = ''
        # Expose standard HTTP/HTTPS entrypoints and map them to host 80/443
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

        # ServiceLB in k3s will bind 80/443 on the node when type is LoadBalancer
        service:
          type: LoadBalancer

        # Enable dashboard (served at port 9000 internally)
        api:
          dashboard: true

        # Providers; publishedService helps external clients form URLs
        providers:
          kubernetesIngress:
            publishedService:
              enabled: true
          kubernetesCRD:
            allowCrossNamespace: true

        # If not using Gateway API yet, keep it disabled to avoid CRD collisions
        experimental:
          kubernetesGateway:
            enabled: false

        # Keep extra flags minimal; dashboard is already enabled above
        additionalArguments:
          - "--log.level=INFO"
      '';
    };
  };
}
