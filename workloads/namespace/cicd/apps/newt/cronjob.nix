# CronJob: pangolin-blueprint-aggregator
#
# Runs once per hour (and can be triggered on-demand by CI via
# `kubectl create job --from=cronjob/pangolin-blueprint-aggregator`).
#
# What it does:
#   1. Lists all ConfigMaps in the cicd namespace labelled
#      pangolin.dobryops.com/resource=true
#   2. Concatenates each ConfigMap's data.resource.yaml field under a
#      `public-resources:` key
#   3. Writes (create-or-update) the result into the
#      `pangolin-blueprint-cicd-gitops` ConfigMap
#
# Reloader (stakater/reloader) then detects the ConfigMap change and
# rolls the Newt pod automatically — no manual intervention needed.
#
# RBAC for the ServiceAccount is in rbac.nix.
{ ... }:

{
  services.k3s.manifests.pangolin-blueprint-aggregator-cronjob.content = {
    apiVersion = "batch/v1";
    kind       = "CronJob";
    metadata   = {
      name      = "pangolin-blueprint-aggregator";
      namespace = "cicd";
    };
    spec = {
      # Run hourly; CI also triggers on-demand after each deploy
      schedule                   = "0 * * * *";
      concurrencyPolicy          = "Replace";
      successfulJobsHistoryLimit = 3;
      failedJobsHistoryLimit     = 3;
      jobTemplate = {
        spec = {
          ttlSecondsAfterFinished = 600;
          template = {
            spec = {
              serviceAccountName = "pangolin-blueprint-aggregator";
              restartPolicy      = "OnFailure";
              containers = [
                {
                  name  = "aggregator";
                  image = "bitnami/kubectl:latest";
                  command = [ "sh" "-c" ];
                  args = [
                    ''
                      set -euo pipefail

                      NAMESPACE="cicd"
                      LABEL="pangolin.dobryops.com/resource=true"
                      TARGET_CM="pangolin-blueprint-cicd-gitops"

                      echo "==> Listing resource ConfigMaps..."
                      CMS=$(kubectl get configmap -n "$NAMESPACE" -l "$LABEL" \
                        -o jsonpath='{.items[*].metadata.name}')

                      if [ -z "$CMS" ]; then
                        echo "No labelled ConfigMaps found — writing empty blueprint."
                        BLUEPRINT="public-resources: []"
                      else
                        BLUEPRINT="public-resources:"
                        for CM in $CMS; do
                          echo "  processing $CM"
                          RESOURCE=$(kubectl get configmap "$CM" -n "$NAMESPACE" \
                            -o jsonpath='{.data.resource\.yaml}')
                          # Indent each line of the resource block by 2 spaces
                          BLUEPRINT="$BLUEPRINT
$(echo "$RESOURCE" | sed 's/^/  /')"
                        done
                      fi

                      echo "==> Writing blueprint to ConfigMap $TARGET_CM..."
                      kubectl create configmap "$TARGET_CM" \
                        -n "$NAMESPACE" \
                        --from-literal=blueprint.yaml="$BLUEPRINT" \
                        --dry-run=client -o yaml \
                        | kubectl apply -f -

                      echo "==> Done."
                    ''
                  ];
                  resources = {
                    requests = { cpu = "50m"; memory = "64Mi"; };
                    limits   = { cpu = "200m"; memory = "128Mi"; };
                  };
                }
              ];
            };
          };
        };
      };
    };
  };
}
