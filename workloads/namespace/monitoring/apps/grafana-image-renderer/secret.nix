# Shared-secret auth token between Grafana and the image-renderer. Mounted
# into the renderer pod via `valueFrom.secretKeyRef` (deployment.nix) and
# consumed by Grafana as the GF_RENDERING_RENDERER_TOKEN env var (rendered
# inline in kube-prometheus-stack/helm.nix's sops template).
{ config, ... }:

{
  sops.templates."monitoring/grafana-image-renderer-secret.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: grafana-image-renderer
        namespace: monitoring
      type: Opaque
      stringData:
        auth-token: ${config.sops.placeholder."monitoring/grafana/renderer_token"}
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/grafana-image-renderer-secret.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
