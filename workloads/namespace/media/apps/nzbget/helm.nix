{ config, ... }:

{
  sops.templates."helm/nzbget.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: nzbget
        namespace: kube-system
      spec:
        repo: https://k8s-at-home.com/charts/
        chart: nzbget
        version: "12.4.2"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          image:
            repository: lscr.io/linuxserver/nzbget
            tag: latest
            pullPolicy: IfNotPresent

          env:
            - name: TZ
              value: "Europe/Helsinki"
            - name: PUID
              value: "1000"
            - name: PGID
              value: "1000"

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

          ingress:
            main:
              enabled: true
              ingressClassName: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-nzbget-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/nzbget/domain"}
                  paths:
                    - path: /
                      pathType: Prefix

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
            nzbget-conf:
              enabled: true
              type: secret
              name: nzbget-conf
              mountPath: "-"

          replicaCount: 1

          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 8Gi

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

          podAnnotations:
            k3s.cattle.io/config-version: "2"

          podSecurityContext:
            fsGroup: 1000

          # k8s-at-home chart expects initContainers as a MAP, not a list.
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
                  mkdir -p /downloads/complete /downloads/tmp /downloads/nzb /downloads/queue /downloads/scripts /downloads/tv /downloads/movies
                  cp /secret/nzbget.conf /config/nzbget.conf
                  chown -R 1000:1000 /config /downloads
                  chmod -R 755 /config /downloads
                  echo "nzbget.conf deployed successfully"
              volumeMounts:
                - name: config
                  mountPath: /config
                - name: downloads
                  mountPath: /downloads
                - name: nzbget-conf
                  mountPath: /secret
                  readOnly: true

          nodeSelector: {}
          tolerations: []
          affinity: {}

          strategy:
            type: RollingUpdate
            rollingUpdate:
              maxSurge: 1
              maxUnavailable: 0
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/nzbget.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
