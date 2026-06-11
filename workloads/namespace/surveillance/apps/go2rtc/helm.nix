{config, ...}: {
  sops.templates."helm/go2rtc.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: go2rtc
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: surveillance
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            # /dev/video0 is a CharDevice and /dev/snd is a directory of
            # CharDevices. Reading them through a hostPath bind-mount
            # requires either privileged=true or an explicit cgroup-device
            # rule. Privileged is the path of least resistance for a homelab
            # single-node cluster.
            securityContext:
              # video=26, audio=17 on this NixOS host. Matches `getent group`.
              # Even with privileged the supplemental groups are still
              # required so go2rtc's process can open the device nodes.
              supplementalGroups:
                - 26
                - 17

          controllers:
            main:
              annotations:
                # Roll the pod when go2rtc.yaml changes.
                configmap.reloader.stakater.com/reload: "go2rtc-config"
              containers:
                main:
                  image:
                    repository: alexxit/go2rtc
                    tag: "1.9.14"
                    pullPolicy: IfNotPresent
                  env:
                    TZ: "Europe/Sofia"
                  securityContext:
                    privileged: true
                  command:
                    - "/usr/local/bin/go2rtc"
                    - "-config"
                    - "/config/go2rtc.yaml"
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 1984
                        initialDelaySeconds: 20
                        periodSeconds: 30
                        timeoutSeconds: 5
                        failureThreshold: 3
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        httpGet:
                          path: /
                          port: 1984
                        initialDelaySeconds: 10
                        periodSeconds: 10
                        timeoutSeconds: 5
                        failureThreshold: 3
                  resources:
                    requests:
                      cpu: 200m
                      memory: 256Mi
                    limits:
                      # ffmpeg does a software libx264 720p30 transcode
                      # plus an Opus encode plus the MJPEG copy in one
                      # process — bursts well past one core. 2000m leaves
                      # room for a second concurrent viewer + the WebRTC
                      # consumer-side packetizer.
                      cpu: 2000m
                      memory: 1Gi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                http:
                  # Tunnel-IP port — every kwg-routed service shares
                  # 100.89.128.16. 8088/8089/8091/8092/8093/8094 are
                  # taken; 8095 is next free.
                  port: 8095
                  targetPort: 1984
                  protocol: TCP

          ingress:
            main:
              className: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: surveillance-go2rtc-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/cam/domain"}
                  paths:
                    - path: /
                      pathType: Prefix
                      service:
                        identifier: main
                        port: http

          persistence:
            config:
              type: configMap
              name: go2rtc-config
              globalMounts:
                - path: /config/go2rtc.yaml
                  subPath: go2rtc.yaml
                  readOnly: true
            video0:
              type: hostPath
              hostPath: /dev/video0
              hostPathType: CharDevice
              globalMounts:
                - path: /dev/video0
            snd:
              type: hostPath
              hostPath: /dev/snd
              hostPathType: Directory
              globalMounts:
                - path: /dev/snd
    '';
    path = "/var/lib/rancher/k3s/server/manifests/go2rtc.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
