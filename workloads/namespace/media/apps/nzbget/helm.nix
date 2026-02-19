{ ... }:

{
  services.k3s.manifests.nzbget-helm.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "nzbget";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://k8s-at-home.com/charts/";
      chart = "nzbget";
      version = "12.4.2";
      targetNamespace = "media";
      createNamespace = false;
      install = true;
      upgrade = true;
      wait = true;
      timeoutSeconds = 300;

      valuesContent = ''
        image:
          repository: lscr.io/linuxserver/nzbget
          tag: latest
          pullPolicy: IfNotPresent

        # Environment variables
        env:
          - name: TZ
            value: "Europe/Helsinki"
          - name: PUID
            value: "1000"
          - name: PGID
            value: "1000"

        # Service configuration
        service:
          main:
            enabled: true
            type: ClusterIP
            ports:
              http:
                port: 6789
                targetPort: 6789
                protocol: TCP
                name: http

        # Ingress configuration with Traefik
        ingress:
          main:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
              traefik.ingress.kubernetes.io/router.middlewares: "media-nzbget-headers@kubernetescrd"
            hosts:
              - host: nzbget.dobryops.com
                paths:
                  - path: /
                    pathType: Prefix

        # Persistence configuration
        persistence:
          config:
            enabled: true
            type: pvc
            accessMode: ReadWriteOnce
            size: 2Gi
            storageClass: local-path
            mountPath: /config
          
          downloads:
            enabled: true
            type: pvc
            existingClaim: media-pvc
            accessMode: ReadWriteMany
            mountPath: /downloads
            subPath: 

        # Pod annotations
        podAnnotations: {}

        # Replica count
        replicaCount: 1

        # Resource limits and requests
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 8Gi

        # Probes for health checking
        livenessProbe:
          httpGet:
            path: /
            port: 6789
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /
            port: 6789
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        # Pod security context
        podSecurityContext:
          fsGroup: 1000

        # Init container: copies nzbget.conf from the SOPS-rendered secret into
        # the config PVC, then fixes ownership.  Runs on every pod start so the
        # config is always in sync with what is declared in Nix.
        # Note: k8s-at-home chart expects initContainers as a MAP, not a list.
        initContainers:
          copy-config:
            image: busybox:1.36
            imagePullPolicy: IfNotPresent
            securityContext:
              runAsUser: 0
              runAsGroup: 0
            command:
              - sh
              - -ceu
              - |
                mkdir -p /config
                cp /secret/nzbget.conf /config/nzbget.conf
                chown -R 1000:1000 /config
                chmod -R 755 /config
                chown -R 1000:1000 /downloads
                chmod -R 755 /downloads
                echo "nzbget.conf deployed successfully"
            volumeMounts:
              - name: config
                mountPath: /config
              - name: downloads
                mountPath: /downloads
              - name: nzbget-conf
                mountPath: /secret
                readOnly: true

        extraVolumes:
          - name: nzbget-conf
            secret:
              secretName: nzbget-conf

        # Node selector
        nodeSelector: {}

        # Tolerations
        tolerations: []

        # Affinity rules
        affinity: {}

        # Strategy
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: 1
            maxUnavailable: 0
      '';
    };
  };
}

