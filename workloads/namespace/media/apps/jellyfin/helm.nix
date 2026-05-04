{ config, ... }:

{
  # Jellyfin HelmChart — rendered via sops.templates so the ingress host
  # is never stored in the Nix store or git repo in plain text.
  sops.templates."helm/jellyfin.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: jellyfin
        namespace: kube-system
      spec:
        repo: https://jellyfin.github.io/jellyfin-helm/
        chart: jellyfin
        version: "3.2.0"
        targetNamespace: media
        createNamespace: false
        valuesContent: |
          image:
            repository: docker.io/jellyfin/jellyfin
            tag: '10.11.8'
          jellyfin:
            env:
              - name: LIBVA_DRIVERS_PATH
                value: /run/opengl-driver/lib/dri
              - name: LIBVA_DRIVER_NAME
                value: iHD
              - name: LD_LIBRARY_PATH
                value: /run/opengl-driver/lib
          resources:
            limits:
              gpu.intel.com/i915: 1
          service:
            type: ClusterIP
            port: 8096
            portName: http
          ingress:
            enabled: true
            className: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              traefik.ingress.kubernetes.io/router.middlewares: media-jellyfin-headers@kubernetescrd
            hosts:
              - host: ${config.sops.placeholder."pangolin/resources/jellyfin/domain"}
                paths:
                  - path: /
                    pathType: Prefix
          persistence:
            media:
              enabled: true
              mountPath: /media
              existingClaim: media-pvc
            config:
              enabled: true
              mountPath: /config
              size: 2Gi
              accessMode: ReadWriteOnce
            cache:
              enabled: false
          # /dev/dri is intentionally NOT mounted as a hostPath here.
          # The Intel device plugin (gpu.intel.com/i915: 1 resource limit) injects
          # the specific GPU device files (card0, renderD128) into the container.
          # Mounting /dev/dri as a directory broke after the kernel started
          # exposing a simpledrm framebuffer under /dev/dri/by-path/ — containerd's
          # recursive mkdir on the bind-mount tree collided with that symlink.
          volumes:
            - name: opengl-driver
              hostPath:
                path: /run/opengl-driver
                type: Directory
            - name: nix-store
              hostPath:
                path: /nix/store
                type: Directory
          volumeMounts:
            - name: opengl-driver
              mountPath: /run/opengl-driver
            - name: nix-store
              mountPath: /nix/store
              readOnly: true
          podSecurityContext:
            supplementalGroups:
              - 44
              - 1
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/jellyfin.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
