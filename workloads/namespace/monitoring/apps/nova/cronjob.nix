{ ... }:

{
  services.k3s.manifests.nova-cronjob.content = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "nova";
      namespace = "monitoring";
      labels."app.kubernetes.io/name" = "nova";
    };
    spec = {
      # Monday 06:00 Europe/Helsinki — same cadence we picked for drift sweeps.
      schedule = "0 6 * * 1";
      timeZone = "Europe/Helsinki";
      concurrencyPolicy = "Forbid";
      successfulJobsHistoryLimit = 3;
      failedJobsHistoryLimit = 1;
      jobTemplate.spec.template.spec = {
        serviceAccountName = "nova";
        restartPolicy = "OnFailure";
        containers = [{
          name = "nova";
          # GitHub releases v3.12.0 but it was never pushed to quay.io;
          # latest available is v3.11.15.
          image = "quay.io/fairwinds/nova:v3.11.15";
          # The image only sets CMD ["/nova"], no ENTRYPOINT. Setting `args`
          # alone would replace CMD entirely (we'd hit busybox's `find`).
          # So `command` pins the binary, `args` pins the subcommand.
          command = [ "/nova" ];
          args = [
            "find"
            "--format=table"
            "--include-all=true"
          ];
          resources = {
            requests = { cpu = "100m"; memory = "128Mi"; };
            limits   = { cpu = "500m"; memory = "512Mi"; };
          };
          securityContext = {
            allowPrivilegeEscalation = false;
            capabilities.drop = [ "ALL" ];
            readOnlyRootFilesystem = true;
            runAsNonRoot = true;
            runAsUser = 65534;
            runAsGroup = 65534;
            seccompProfile.type = "RuntimeDefault";
          };
        }];
      };
    };
  };
}
