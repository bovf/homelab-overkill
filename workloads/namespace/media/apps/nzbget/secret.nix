{ config, ... }:

{
  # SOPS secret for NZBGet credentials
  sops.secrets."media/nzbget/password" = {
    sopsFile = ../../../secrets.yaml;
    format = "yaml";
    mode = "0600";
  };

  # Create the Kubernetes secret from SOPS
  sops.templates."media/nzbget-credentials.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: nzbget-credentials
        namespace: media
      type: Opaque
      stringData:
        password: ${config.sops.placeholder."media/nzbget/password"}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/nzbget-credentials.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
