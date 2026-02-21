# Deploys a dedicated Newt instance for CI/CD-managed services in the cicd namespace.
#
# Key design decisions:
# - Mounts a ConfigMap (not a Secret) as the blueprint — domains are not secrets,
#   and using a ConfigMap allows Reloader to watch it via the configmap annotation.
# - The blueprint ConfigMap `pangolin-blueprint-cicd-gitops` is populated by the
#   aggregator Job (job.nix), NOT by sops-nix. Nix only provisions the tunnel
#   credentials (secret.nix). The blueprint content is fully CI-managed.
# - Reloader annotation: configmap.reloader.stakater.com/reload triggers a pod
#   restart whenever the master blueprint ConfigMap changes.
{ ... }:

{
  services.k3s.manifests.newt-cicd.content = {
    apiVersion = "helm.cattle.io/v1";
    kind       = "HelmChart";
    metadata   = {
      name      = "newt-cicd";
      namespace = "kube-system";
    };
    spec = {
      repo            = "https://charts.fossorial.io";
      chart           = "newt";
      targetNamespace = "cicd";
      createNamespace = false;
      valuesContent   = ''
        global:
          podAnnotations:
            # Reloader watches this ConfigMap and rolls the pod when it changes.
            # The aggregator job updates this ConfigMap on every CI deploy that
            # adds or modifies a pangolin resource.
            configmap.reloader.stakater.com/reload: "pangolin-blueprint-cicd-gitops"

        newtInstances:
          - name: cicd-gitops
            enabled: true

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
