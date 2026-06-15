{...}: let
  nixConfig = ''
    experimental-features = nix-command flakes
    substituters = https://cache.dobryops.com/badwater https://cache.nixos.org
    trusted-public-keys = badwater:GfR4TMrcaFJYnsldgBY+P27G620qwd9JRz831f6OxpU= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
  '';

  primeScript = ''
    set -euo pipefail
    export HOME=/tmp/attic-home
    export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
    mkdir -p "$HOME"

    echo "Installing the same tool refs used by the GitLab Nix runner"
    nix profile install \
      nixpkgs#attic-client \
      nixpkgs#nix-update

    ATTIC="$HOME/.nix-profile/bin/attic"
    test -x "$ATTIC"
    ATTIC_CLIENT_PATH="$(nix path-info nixpkgs#attic-client)"
    NIX_UPDATE_PATH="$(nix path-info nixpkgs#nix-update)"

    "$ATTIC" login --set-default local http://attic-cache.proxy.svc.cluster.local:8102 "$ATTIC_TOKEN"

    echo "Priming badwater with runner tool closures:"
    echo "  $ATTIC_CLIENT_PATH"
    echo "  $NIX_UPDATE_PATH"
    "$ATTIC" push --ignore-upstream-cache-filter badwater "$ATTIC_CLIENT_PATH" "$NIX_UPDATE_PATH"
  '';

  container = {
    name = "prime";
    image = "nixos/nix:2.34.7";
    imagePullPolicy = "IfNotPresent";
    command = ["/bin/sh" "-ec"];
    args = [primeScript];
    env = [
      {
        name = "NIX_CONFIG";
        value = nixConfig;
      }
    ];
    envFrom = [{secretRef.name = "attic-cache-secret";}];
    resources = {
      requests = {
        cpu = "1";
        memory = "2Gi";
      };
      limits = {
        cpu = "4";
        memory = "8Gi";
      };
    };
  };

  podSpec = {
    restartPolicy = "OnFailure";
    containers = [container];
  };
in {
  services.k3s.manifests.attic-cache-prime-runner-tools-job.content = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "attic-cache-prime-runner-tools-v4";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      backoffLimit = 3;
      template = {
        metadata.labels.app = "attic-cache-prime-runner-tools";
        spec = podSpec;
      };
    };
  };

  services.k3s.manifests.attic-cache-prime-runner-tools-cronjob.content = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "attic-cache-prime-runner-tools";
      namespace = "proxy";
      labels.app = "attic-cache";
    };
    spec = {
      schedule = "43 2 * * 0";
      concurrencyPolicy = "Forbid";
      successfulJobsHistoryLimit = 2;
      failedJobsHistoryLimit = 3;
      jobTemplate.spec = {
        backoffLimit = 3;
        template = {
          metadata.labels.app = "attic-cache-prime-runner-tools";
          spec = podSpec;
        };
      };
    };
  };
}
