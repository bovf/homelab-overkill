{pkgs, ...}: let
  atticClient = pkgs.attic-client;
in {
  services.k3s.manifests.attic-cache-bootstrap-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "attic-cache-bootstrap-v5";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      backoffLimit = 6;
      template = {
        metadata.labels.app = "attic-cache-bootstrap";
        spec = {
          restartPolicy = "OnFailure";
          containers = [
            {
              name = "bootstrap";
              image = "busybox:latest";
              imagePullPolicy = "IfNotPresent";
              command = ["/bin/sh" "-ec"];
              args = [
                ''
                  export HOME=/tmp/attic-home
                  endpoint=http://attic-cache.proxy.svc.cluster.local:8102
                  mkdir -p "$HOME"

                  # `attic login` only writes local credentials; it does not
                  # prove the server is ready. Probe the service first.
                  for i in $(seq 1 60); do
                    wget -qO /dev/null "$endpoint/" && break
                    echo "waiting for attic-cache Service ($i/60)"
                    sleep 5
                  done
                  wget -qO /dev/null "$endpoint/"

                  ${atticClient}/bin/attic login --set-default local "$endpoint" "$ATTIC_ADMIN_TOKEN"

                  if wget -qO /dev/null "$endpoint/_api/v1/cache-config/badwater"; then
                    echo "badwater cache already exists"
                  else
                    ${atticClient}/bin/attic cache create --public badwater
                  fi

                  ${atticClient}/bin/attic cache configure --public --retention-period "90 days" badwater
                  ${atticClient}/bin/attic cache info badwater
                ''
              ];
              env = [
                {
                  name = "SSL_CERT_FILE";
                  value = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
                }
              ];
              envFrom = [{secretRef.name = "attic-cache-secret";}];
              volumeMounts = [
                {
                  name = "nix-store";
                  mountPath = "/nix/store";
                  readOnly = true;
                }
              ];
            }
          ];
          volumes = [
            {
              name = "nix-store";
              hostPath = {
                path = "/nix/store";
                type = "Directory";
              };
            }
          ];
        };
      };
    };
  };
}
