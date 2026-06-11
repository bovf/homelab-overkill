{config, ...}: {
  sops.templates."helm/qbittorrent.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: qbittorrent
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            securityContext:
              fsGroup: 1000

          controllers:
            main:
              initContainers:
                copy-config:
                  image:
                    repository: busybox
                    tag: "1.38.0"
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

              containers:
                # VPN client. Sets up WireGuard tunnel + iptables kill-switch.
                # All other containers in this pod inherit the same netns and
                # are forced to route through the VPN.
                gluetun:
                  image:
                    repository: ghcr.io/qdm12/gluetun
                    tag: v3.40.0
                  securityContext:
                    capabilities:
                      add: [ "NET_ADMIN" ]
                  env:
                    TZ: "Europe/Helsinki"
                    # Allow direct (non-VPN) traffic to/from the cluster pod &
                    # service CIDRs so Traefik can reach the WebUI on 8080.
                    FIREWALL_OUTBOUND_SUBNETS: "10.42.0.0/16,10.43.0.0/16"
                    FIREWALL_INPUT_PORTS: "8080"
                    # Avoid clashing with cluster DNS.
                    DOT: "off"
                    DNS_KEEP_NAMESERVER: "on"
                    HEALTH_VPN_DURATION_INITIAL: "120s"
                  envFrom:
                    - secretRef:
                        name: qbittorrent-vpn-creds

                qbittorrent:
                  image:
                    repository: ghcr.io/linuxserver/qbittorrent
                    tag: "5.2.1"
                  env:
                    TZ: "Europe/Helsinki"
                    PUID: "1000"
                    PGID: "1000"
                    WEBUI_PORT: "8080"
                  resources:
                    requests:
                      memory: 2000M
                    limits:
                      memory: 8000M
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 8080
                        initialDelaySeconds: 60
                        periodSeconds: 30
                        failureThreshold: 5
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 8080
                        initialDelaySeconds: 30
                        periodSeconds: 15

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  port: 8080
                  protocol: HTTP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: media-qbittorrent-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/qbittorrent/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: 8080

          persistence:
            config:
              size: 2Gi
              accessMode: ReadWriteOnce
              advancedMounts:
                main:
                  qbittorrent:
                    - path: /config
                  copy-config:
                    - path: /config
            downloads:
              existingClaim: media-pvc
              advancedMounts:
                main:
                  qbittorrent:
                    - path: /downloads
            qbittorrent-conf:
              type: secret
              name: qbittorrent-conf
              advancedMounts:
                main:
                  copy-config:
                    - path: /secret
                      readOnly: true
            tun:
              type: hostPath
              hostPath: /dev/net/tun
              hostPathType: CharDevice
              advancedMounts:
                main:
                  gluetun:
                    - path: /dev/net/tun
    '';
    path = "/var/lib/rancher/k3s/server/manifests/qbittorrent.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
