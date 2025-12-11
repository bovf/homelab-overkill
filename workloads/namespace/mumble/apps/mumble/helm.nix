{ ... }:

{
  services.k3s.manifests.mumble-server.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "mumble-server";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://syntax3rror404.github.io/helm-charts/charts";
      chart = "mumble";
      version = "1.0.0";
      targetNamespace = "mumble";
      createNamespace = false;
      valuesContent = ''
        replicaCount: 1

        image:
          repository: phlak/mumble
          pullPolicy: IfNotPresent
          tag: "latest"

        nameOverride: ""
        fullnameOverride: "mumble-server"

        serviceAccount:
          create: true
          annotations: {}
          name: ""

        podAnnotations: {}

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

        service:
          type: ClusterIP
          annotations: {}
          ports:
            mumble:
              port: 64738
              targetPort: 64738
              protocol: UDP

        persistence:
          enabled: true
          storageClass: "local-path"
          accessMode: ReadWriteOnce
          size: 1Gi

        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 256Mi

        livenessProbe:
          enabled: false

        readinessProbe:
          enabled: false

        nodeSelector: {}

        tolerations: []

        affinity: {}

        mumbleServer:
          welcometext: "Welcome to Mumble"
          serverpassword: "krisipisi"
          users: 100
          servername: "BigFuckSmallDiscord"
          port: 64738
          bandwidth: 128000
          logLevel: 1
      '';
    };
  };
}
