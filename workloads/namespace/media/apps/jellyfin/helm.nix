{ ... }:

{
  # Jellyfin deployment 
  services.k3s.manifests.jellyfin.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "jellyfin";
      namespace = "kube-system";
    };
    spec = {
      repo = "https://jellyfin.github.io/jellyfin-helm/";
      chart = "jellyfin";
      version = "2.3.0";
      targetNamespace = "media";
      createNamespace = false;
      valuesContent = ''
        image:
          repository: docker.io/jellyfin/jellyfin
          tag: '10.10.7'
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
          className: 'traefik'
          annotations: 
            traefik.ingress.kubernetes.io/router.entrypoints: 'web,websecure' 
            traefik.ingress.kubernetes.io/router.middlewares: 'media-jellyfin-headers@kubernetescrd' 
          hosts: 
            - host: jellyfin.dobryops.com
              paths:
                - path: '/'
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
        volumes:
          - name: dev-dri
            hostPath:
              path: /dev/dri
              type: Directory
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
          - name: dev-dri
            mountPath: /dev/dri
          - name: nix-store
            mountPath: /nix/store
            readOnly: true
        podSecurityContext:
          supplementalGroups:
            - 44  # video group on Linux, needed to access /dev/dri devices
            - 1
      '';
    };
  };

}
