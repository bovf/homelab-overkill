{ ... }:

{
  services.k3s.manifests.keel.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "keel";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://charts.keel.sh";
      chart = "keel";
      version = "1.2.0";
      targetNamespace = "cicd";
      createNamespace = false;
      valuesContent = ''
        rbac:
          enabled: true
        serviceAccount:
          create: true

        # Watch all namespaces; per-deployment opt-in via keel.sh/* annotations.
        watchNamespace: ""

        # Disable the web UI / approvals API — we don't gate updates manually.
        helmProvider:
          enabled: false
        webhookRelay:
          enabled: false
        webhook:
          enabled: false
        slack:
          enabled: false
        mattermost:
          enabled: false
        hipchat:
          enabled: false
        basicauth:
          enabled: false

        # Poll-based trigger only (no webhooks from registries).
        polling:
          enabled: true

        resources:
          requests:
            cpu: 20m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 256Mi
      '';
    };
  };
}
