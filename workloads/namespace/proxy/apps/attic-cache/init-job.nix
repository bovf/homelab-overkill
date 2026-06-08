{pkgs, ...}: let
  atticClient = pkgs.attic-client;
in {
  services.k3s.manifests.attic-cache-bootstrap-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "attic-cache-bootstrap-v3";
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
                  mkdir -p "$HOME"

                  for i in $(seq 1 60); do
                    if ${atticClient}/bin/attic login --set-default local http://attic-cache.proxy.svc.cluster.local:8102 "$ATTIC_ADMIN_TOKEN" >/tmp/attic-login.log 2>&1; then
                      break
                    fi
                    cat /tmp/attic-login.log || true
                    echo "waiting for attic-cache Service ($i/60)"
                    sleep 5
                  done

                  ${atticClient}/bin/attic login --set-default local http://attic-cache.proxy.svc.cluster.local:8102 "$ATTIC_ADMIN_TOKEN"

                  if ${atticClient}/bin/attic cache info badwater >/tmp/attic-cache-info.log 2>&1; then
                    echo "badwater cache already exists"
                    cat /tmp/attic-cache-info.log
                    ${atticClient}/bin/attic cache configure --public --retention-period "90 days" badwater
                  else
                    cat /tmp/attic-cache-info.log || true
                    ${atticClient}/bin/attic cache create --public badwater
                    ${atticClient}/bin/attic cache configure --public --retention-period "90 days" badwater
                  fi

                  ${atticClient}/bin/attic cache info badwater
                ''
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
