# Dedicated newt instance for CI-managed services. Blueprint is in a
# ConfigMap aggregated from labelled resource CMs (not via sops).
{...}: {
  services.k3s.manifests.newt-cicd.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "newt-cicd";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://charts.fossorial.io";
      chart = "newt";
      version = "1.5.0";
      targetNamespace = "cicd";
      createNamespace = false;
      valuesContent = ''
        global:
          image:
            tag: "1.19.1@sha256:c89f01cb387bf6c598959036cbf56306b068a43e8784345bee7398b7af8ee2e1"
          podAnnotations:
            configmap.reloader.stakater.com/reload: "pangolin-blueprint-cicd-gitops"

        newtInstances:
          - name: cicd-gitops
            enabled: true

            # Outbound-only — disable the chart's Service to avoid
            # klipper-ServiceLB claiming ports the engineer newt holds.
            service:
              enabled: false

            auth:
              existingSecretName: newt-cred-cicd-gitops
              keys:
                endpointKey: PANGOLIN_ENDPOINT
                idKey: NEWT_ID
                secretKey: NEWT_SECRET

            extraEnv:
              BLUEPRINT_FILE: "/config/blueprint.yaml"
              # Credentials come from the Secret, not a writable config cache.
              CONFIG_FILE: "/dev/null"

            extraVolumes:
              - name: pangolin-blueprint
                configMap:
                  name: pangolin-blueprint-cicd-gitops

            extraVolumeMounts:
              - name: pangolin-blueprint
                mountPath: "/config"
                readOnly: true

            resources:
              requests:
                cpu: 50m
                memory: 64Mi
              limits:
                cpu: 200m
                memory: 128Mi
      '';
    };
  };
}
