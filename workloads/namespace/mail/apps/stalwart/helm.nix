# Stalwart mail server — single pod via bjw-s app-template. Listens on
# 25/465/587/993 (SMTP/IMAP) + 8080 (admin UI HTTP). Service exposes those
# ports on the kwg tunnel IP (100.89.128.16) so kube-proxy externalIPs
# DNATs Pangolin-tunnelled traffic to the pod. LAN-direct hits the admin
# UI via traefik + the wildcard cert (see lan-services aggregator + the
# Ingress below).
#
# Stalwart binary lives at /usr/local/bin/stalwart and looks for
# /opt/stalwart/etc/config.toml by default. The initContainer copies the
# sops-rendered config + DKIM key into that path on every pod start.
{ config, ... }:

{
  sops.templates."helm/stalwart.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: stalwart
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: mail
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              # Roll the pod when the rendered config / DKIM key changes
              # or when cert-manager renews the wildcard TLS Secret.
              secret.reloader.stakater.com/reload: "stalwart-config,wildcard-dobryops-com-tls"
            securityContext:
              fsGroup: 0
              fsGroupChangePolicy: OnRootMismatch

          controllers:
            main:
              type: statefulset
              initContainers:
                copy-config:
                  image:
                    repository: busybox
                    tag: "1.36"
                  securityContext:
                    runAsUser: 0
                    runAsGroup: 0
                  command:
                    - sh
                    - -ceu
                    - |
                      mkdir -p /opt/stalwart/etc
                      cp /secret/config.toml /opt/stalwart/etc/config.toml
                      cp /secret/dkim.key    /opt/stalwart/etc/dkim.key
                      chmod 600 /opt/stalwart/etc/config.toml /opt/stalwart/etc/dkim.key
                      echo "stalwart config staged"
              containers:
                main:
                  image:
                    repository: stalwartlabs/stalwart
                    tag: "v0.13.0"
                  env:
                    TZ: "Europe/Helsinki"
                  securityContext:
                    capabilities:
                      add: ["NET_BIND_SERVICE"]
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        tcpSocket:
                          port: 8083
                        initialDelaySeconds: 30
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 5
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        tcpSocket:
                          port: 8083
                        initialDelaySeconds: 15
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 100m
                      memory: 256Mi
                    limits:
                      cpu: 1000m
                      memory: 1Gi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                smtp:
                  port: 25
                  protocol: TCP
                submission:
                  port: 587
                  protocol: TCP
                submissions:
                  port: 465
                  protocol: TCP
                imaps:
                  port: 993
                  protocol: TCP
                http:
                  port: 8083
                  protocol: TCP

          ingress:
            mailadmin:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/mailadmin/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            data:
              accessMode: ReadWriteOnce
              size: 10Gi
              storageClass: local-path
              globalMounts:
                - path: /opt/stalwart
            stalwart-config:
              type: secret
              name: stalwart-config
              advancedMounts:
                main:
                  copy-config:
                    - path: /secret
                      readOnly: true
            wildcard-tls:
              type: secret
              name: wildcard-dobryops-com-tls
              advancedMounts:
                main:
                  main:
                    - path: /etc/stalwart/certs
                      readOnly: true
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/stalwart.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
