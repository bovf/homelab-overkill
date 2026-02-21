{ config, lib, ... }:

let
  inherit (lib) concatStringsSep mapAttrsToList;

  blueprintSecrets = concatStringsSep ","
    (mapAttrsToList (name: _: "pangolin-blueprint-${name}") config.workloads.pangolinInstances);

  # Build one YAML list entry per declared pangolinInstance.
  # Each instance mounts its own blueprint secret (pangolin-blueprint-<name>).
  renderInstance = instanceName: _instanceCfg: ''
    - name: ${instanceName}
      enabled: true

      auth:
        existingSecretName: newt-cred
        keys:
          endpointKey: PANGOLIN_ENDPOINT
          idKey: NEWT_ID
          secretKey: NEWT_SECRET

      extraEnv:
        BLUEPRINT_FILE: "/config/blueprint.yaml"

      extraVolumes:
        - name: pangolin-blueprint
          secret:
            secretName: pangolin-blueprint-${instanceName}

      extraVolumeMounts:
        - name: pangolin-blueprint
          mountPath: "/config"
          readOnly: true
  '';

  instancesYaml = concatStringsSep ""
    (mapAttrsToList renderInstance config.workloads.pangolinInstances);

in
{
  services.k3s.manifests.newt.content = {
    apiVersion = "helm.cattle.io/v1";
    kind       = "HelmChart";
    metadata = {
      name      = "newt";
      namespace = "kube-system";
    };
    spec = {
      repo            = "https://charts.fossorial.io";
      chart           = "newt";
      targetNamespace = "pangolin";
      createNamespace = false;
      valuesContent   = ''
        global:
          podAnnotations:
            secret.reloader.stakater.com/reload: "${blueprintSecrets}"

        newtInstances:
        ${instancesYaml}
      '';
    };
  };
}
