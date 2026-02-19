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
      version = "1.0.1";
      targetNamespace = "mumble";
      chart = "mumble";

      valuesContent = ''
        image:
          repository: ghcr.io/mumble-voip/mumble-server
          tag: v1.5.857-0
          pullPolicy: IfNotPresent

        service:
          type: NodePort
          externalTrafficPolicy: Local
          ports:
            - name: mumble-tcp
              port: 64738
              targetPort: 64738
              protocol: TCP
              nodePort: 11269
            - name: mumble-udp
              port: 64738
              targetPort: 64738
              protocol: UDP
              nodePort: 11269

        persistence:
          enabled: false # Using secret-backed config instead of PVC

        environment:
          # Tell the container to use your mounted SOPS config
          customConfigFile: "/data/mumble_server_config.ini"

        # Native Cert-Manager integration for the chart
        certificate:
          generate: false
          existingSecret: "mumble-tls-cert-xv6sf"

        # Mount your SOPS secret
        extraVolumes:
          - name: config
            secret:
              secretName: mumble-config
        
        extraVolumeMounts:
          - name: config
            mountPath: /data
            readOnly: true

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
