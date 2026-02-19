{ config, ... }:

{
  # Need to figure out a way to have NordVPN work with QB, or get another VPN. Gluetun disabled for now.
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
            image:
              repository: qmcgaw/gluetun
              tag: v3.40.0
              pullPolicy: IfNotPresent
            securityContext:
              privileged: true
              capabilities:
                add:
                  - NET_ADMIN
            vpn:
              provider: "nordvpn"
              type: "wireguard"
              wireguard:
                privateKeyExistingSecret: nordvpn-secret
                privateKeyExistingSecretKey: privateKey
                addresses: "10.5.0.2/32"
            credentials:
              create: false
              existingSecret: nordvpn-secret
            settings:
              FIREWALL: "on"
              FIREWALL_OUTBOUND_SUBNETS: "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
              DNS_ADDRESS: "1.1.1.1"
              HEALTH_SERVER_PORT: "8000"
              SERVER_ALLOWLIST: "qbittorrent:8080,qbittorrent:6881"
              FIREWALL_INPUT_PORTS: "8080,6881"
            extraEnv:
              - name: LOG_LEVEL
                value: "info"
            extraPorts:
              - name: bittorrent-udp
                containerPort: 6881
                protocol: UDP
              - name: bittorrent-tcp
                containerPort: 6881
                protocol: TCP
            resources:
              limits:
                cpu: 300m
                memory: 256Mi
              requests:
                cpu: 100m
                memory: 128Mi
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
