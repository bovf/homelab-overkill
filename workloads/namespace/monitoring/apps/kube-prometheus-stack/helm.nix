{ ... }:
{
  services.k3s.manifests.prometheus-stack.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "kube-prometheus-stack";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://prometheus-community.github.io/helm-charts";
      chart = "kube-prometheus-stack";
      version = "58.5.0";
      targetNamespace = "monitoring";
      createNamespace = true;
      valuesContent = ''
        grafana:
          service:
            type: ClusterIP
            port: 32000
          admin:
            existingSecret: grafana-admin-password
            userKey: admin-user
            passwordKey: admin-password
          ingress:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.middlewares: monitoring-grafana-headers@kubernetescrd
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
            path: /
            pathType: Prefix
            hosts:
              - grafana.dobryops.com
      '';
    };
  };
}
