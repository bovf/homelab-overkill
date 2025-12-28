{ ... }:

{
  services.k3s.manifests.newt.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "newt";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://charts.fossorial.io";
      chart = "newt";
      targetNamespace = "pangolin";
      createNamespace = false;
      valuesContent = ''
        newtInstances:
          - name: main
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
                configMap:
                  name: pangolin-blueprint

            extraVolumeMounts:
              - name: pangolin-blueprint
                mountPath: "/config"
                readOnly: true
      '';
    };
  };
}
