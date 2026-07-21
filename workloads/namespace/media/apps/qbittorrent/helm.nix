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

                # ProtonVPN assigns an ephemeral forwarded port. Gluetun writes
                # it to /gluetun/forwarded_port; this sidecar pushes it into
                # qBittorrent's Web API so inbound peers use the current port.
                port-sync:
                  image:
                    repository: curlimages/curl
                    tag: "8.21.0"
                  envFrom:
                    - secretRef:
                        name: qbittorrent-conf
                  command:
                    - sh
                    - -ceu
                    - |
                      last=""
                      while true; do
                        if [ -s /gluetun/forwarded_port ]; then
                          port="$(tr -dc '0-9' < /gluetun/forwarded_port)"
                          if [ -n "$port" ] && [ "$port" != "$last" ]; then
                            echo "Updating qBittorrent listen port to $port"
                            until curl -fsS -c /tmp/qbit.cookie \
                              -H "Referer: http://127.0.0.1:8080" \
                              --data-urlencode "username=$QBIT_USERNAME" \
                              --data-urlencode "password=$QBIT_PASSWORD" \
                              http://127.0.0.1:8080/api/v2/auth/login >/dev/null; do
                              sleep 5
                            done
                            curl -fsS -b /tmp/qbit.cookie \
                              -H "Referer: http://127.0.0.1:8080" \
                              --data-urlencode "json={\"listen_port\":$port,\"upnp\":false}" \
                              http://127.0.0.1:8080/api/v2/app/setPreferences
                            last="$port"
                          fi
                        fi
                        sleep 60
                      done

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
            gluetun-data:
              type: emptyDir
              advancedMounts:
                main:
                  gluetun:
                    - path: /gluetun
                  port-sync:
                    - path: /gluetun
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
