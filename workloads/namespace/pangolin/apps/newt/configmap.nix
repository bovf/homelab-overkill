# hosts/engineer/pangolin-blueprint.nix
{ ... }:

{
  services.k3s.manifests.pangolin-blueprint.content = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "pangolin-blueprint";
      namespace = "pangolin";
    };
    data = {
      "blueprint.yaml" = ''
        public-resources:
          jellyfin:
            name: Jellyfin Media Server
            protocol: http
            full-domain: jellyfin.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: jellyfin.dobryops.com

          jellyseerr:
            name: Jellyseerr
            protocol: http
            full-domain: jellyseerr.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: jellyseerr.dobryops.com

          sonarr:
            name: Sonarr
            protocol: http
            full-domain: sonarr.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: sonarr.dobryops.com

          radarr:
            name: Radarr
            protocol: http
            full-domain: radarr.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: radarr.dobryops.com

          bazarr:
            name: Bazarr
            protocol: http
            full-domain: bazarr.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: bazarr.dobryops.com

          prowlarr:
            name: Prowlarr
            protocol: http
            full-domain: prowlarr.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: prowlarr.dobryops.com

          qbittorrent:
            name: qBittorrent VPN
            protocol: http
            full-domain: qbittorrent.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: qbittorrent.dobryops.com

          nzbget:
            name: NZBGet
            protocol: http
            full-domain: nzbget.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: nzbget.dobryops.com

          grafana:
            name: Grafana Dashboard
            protocol: http
            full-domain: grafana.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: grafana.dobryops.com

          prometheus:
            name: Prometheus
            protocol: http
            full-domain: prometheus.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: prometheus.dobryops.com

          minio:
            name: MinIO Object Storage
            protocol: http
            full-domain: minio.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: minio.dobryops.com

          minio-console:
            name: MinIO Console
            protocol: http
            full-domain: console.minio.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: console.minio.dobryops.com

          gitlab:
            name: GitLab
            protocol: http
            full-domain: gitlab.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: gitlab.dobryops.com
              - name: X-Gitlab-Wildcard-Host
                value: gitlab.dobryops.com

          reactive-resume:
            name: Reactive Resume
            protocol: http
            full-domain: resume.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik.kube-system.svc.cluster.local
                method: https
                port: 443
            headers:
              - name: Host
                value: resume.dobryops.com

          traefik-dashboard:
            name: Traefik Dashboard
            protocol: http
            full-domain: traefik.dobryops.com
            targets:
              - site: several-seven-banded-armadillo
                hostname: traefik-dashboard.kube-system.svc.cluster.local
                method: http
                port: 9000
            headers:
              - name: X-Forwarded-Proto
                value: https

          mumble:
            name: Mumble Server
            protocol: udp
            proxy-port: 64738
            targets:
              - site: several-seven-banded-armadillo
                hostname: mumble-server.mumble.svc.cluster.local
                port: 64738
      '';
    };
  };
}
