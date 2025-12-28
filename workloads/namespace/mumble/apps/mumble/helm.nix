{ config, pkgs, ... }:

{
  services.k3s.manifests.mumble-server.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "mumble-server";
      namespace = "kube-system";
    };
    spec = {
      chart = "oci://ghcr.io/juniorjpdj/charts/mumble-server";
      version = "0.1.32";
      targetNamespace = "mumble";

      valuesContent = ''
        replicaCount: 1

        image:
          repository: phlak/mumble
          pullPolicy: IfNotPresent
          tag: "latest"

        fullnameOverride: "mumble-server"

        podSecurityContext:
          fsGroup: 1000
          runAsUser: 1000
          runAsNonRoot: true

        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
          readOnlyRootFilesystem: false

        # bjw-s style: services live under service.<name> (main)
        service:
          main:
            enabled: true
            type: ClusterIP
            annotations: {}

        # Only Secret-backed config to avoid persistence.type PVC validation issues
        persistence:
          config:
            enabled: true
            type: secret
            name: mumble-config
            subPath: mumble_server_config.ini
            mountPath: /data/

        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 256Mi
      '';
    };
  };
}
