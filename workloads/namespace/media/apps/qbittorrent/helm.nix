{ config, ... }:

{
  sops.templates."helm/qbittorrent.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: qbittorrent
        namespace: kube-system
      spec:
        repo: https://rtomik.github.io/helm-charts/
        chart: qbittorrent-vpn
        version: "0.0.1"
        targetNamespace: media
        createNamespace: true
        valuesContent: |
          qbittorrent:
            image:
              repository: ghcr.io/linuxserver/qbittorrent
              tag: "5.1.0"
            env:
              - name: TZ
                value: Europe/Helsinki
              - name: PUID
                value: "1000"
              - name: PGID
                value: "1000"
            bittorrentPort: 6881
            resources:
              limits:
                memory: 8000M
              requests:
                memory: 2000M
            service:
              type: ClusterIP
              port: 8080
            persistence:
              downloads:
                enabled: true
                existingClaim: media-pvc
                mountPath: downloads/
                subPath: downloads/
          gluetun:
            enabled: false
          ingress:
            enabled: true
            className: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              traefik.ingress.kubernetes.io/router.middlewares: media-qbittorrent-headers@kubernetescrd
            hosts:
              - host: ${config.sops.placeholder."pangolin/resources/qbittorrent/domain"}
                paths:
                  - path: /
                    pathType: Prefix
          securityContext:
            runAsUser: 1000
            runAsGroup: 1000
            fsGroup: 1000
            runAsNonRoot: true
          podSecurityContext:
            fsGroup: 1000
          initContainers:
            - name: copy-config
              image: busybox:1.36
              securityContext:
                runAsUser: 0
                runAsGroup: 0
              command:
                - sh
                - -ceu
                - |
                  mkdir -p /config/qBittorrent
                  cp /secret/qbittorrent.conf /config/qBittorrent/qBittorrent.conf
                  chown -R 1000:1000 /config
                  chmod -R 755 /config
              volumeMounts:
                - name: config
                  mountPath: /config
                - name: qbittorrent-conf
                  mountPath: /secret
                  readOnly: true
          extraVolumes:
            - name: qbittorrent-conf
              secret:
                secretName: qbittorrent-conf
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/qbittorrent.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
