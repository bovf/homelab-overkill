{...}: {
  sops.templates."helm/gitlab-nix-cache-runner.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: gitlab-nix-cache-runner
        namespace: kube-system
      spec:
        repo: https://charts.gitlab.io/
        chart: gitlab-runner
        version: "0.88.3"
        targetNamespace: cicd
        createNamespace: false
        valuesContent: |
          gitlabUrl: http://gitlab-webservice-default.cicd.svc.cluster.local:8181

          replicas: 1
          concurrent: 1
          checkInterval: 30

          rbac:
            create: true

          serviceAccount:
            create: true
            name: gitlab-nix-cache-runner

          runners:
            name: homelab-overkill-nix-cache
            locked: false
            tags: "nix,nix-heavy,nix-cache,homelab-overkill"
            runUntagged: false
            protected: true
            secret: gitlab-nix-cache-runner-secret
            config: |
              [[runners]]
                executor = "kubernetes"
                request_concurrency = 2
                environment = [
                  "NIX_CONFIG=experimental-features = nix-command flakes\nsubstituters = https://cache.dobryops.com/badwater https://cache.nixos.org\ntrusted-public-keys = badwater:GfR4TMrcaFJYnsldgBY+P27G620qwd9JRz831f6OxpU= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=",
                  "ATTIC_SERVER=https://cache.dobryops.com"
                ]
                pre_build_script = """
                  set -euo pipefail
                  nix profile install \
                    nixpkgs#attic-client \
                    nixpkgs#nix-update
                """
                [runners.kubernetes]
                  namespace = "cicd"
                  image = "nixos/nix:2.28.3"
                  pull_policy = "if-not-present"
                  cpu_request = "2"
                  memory_request = "4Gi"
                  cpu_limit = "10"
                  memory_limit = "16Gi"
                  helper_cpu_request = "100m"
                  helper_memory_request = "128Mi"
                  helper_cpu_limit = "1"
                  helper_memory_limit = "512Mi"
                  poll_timeout = 600
                  [runners.kubernetes.node_selector]
                    "kubernetes.io/arch" = "amd64"

          resources:
            requests:
              cpu: 50m
              memory: 128Mi
            limits:
              cpu: 250m
              memory: 256Mi
    '';
    path = "/var/lib/rancher/k3s/server/manifests/gitlab-nix-cache-runner.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
