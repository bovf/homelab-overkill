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
            tag: "1.16@sha256:345fdeb369be6608d82c41d70637636c78b2c04a6112ff6ec20fc21c48afc899"
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
