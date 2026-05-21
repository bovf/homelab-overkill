{ config, ... }:

let
  matrixDomain = config.sops.placeholder."pangolin/resources/matrix/domain";
in
{
  # restrictBaseUrl locks synapse-admin to our homeserver so the login
  # form can't be pointed elsewhere. Rendered via sops.templates only to
  # keep the domain out of git.
  sops.templates."matrix/synapse-admin-config.yaml" = {
    content = ''
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: synapse-admin-config
        namespace: matrix
      data:
        config.json: |
          {
            "restrictBaseUrl": "https://${matrixDomain}"
          }
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/synapse-admin-config.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
