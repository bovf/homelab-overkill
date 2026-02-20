{ config, ... }:

{
  sops.templates."helm/homepage.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: homepage
        namespace: kube-system
      spec:
        repo: https://jameswynn.github.io/helm-charts
        chart: homepage
        version: "2.1.0"
        targetNamespace: homepage
        createNamespace: false
        valuesContent: |
          image:
            repository: ghcr.io/gethomepage/homepage
            tag: latest
            pullPolicy: Always

          service:
            main:
              type: ClusterIP
              ports:
                http:
                  port: 3000

          ingress:
            main:
              enabled: true
              ingressClassName: traefik
              annotations:
                traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
                traefik.ingress.kubernetes.io/router.middlewares: homepage-homepage-headers@kubernetescrd
              hosts:
                - host: ${config.sops.placeholder."pangolin/resources/homepage/domain"}
                  paths:
                    - path: /
                      pathType: Prefix

          resources:
            requests:
              cpu: 10m
              memory: 50Mi
            limits:
              cpu: 500m
              memory: 200Mi

          enableRbac: true
          serviceAccount:
            create: true

          env:
            - name: HOMEPAGE_ALLOWED_HOSTS
              value: ${config.sops.placeholder."pangolin/resources/homepage/domain"}

          config:
            settings:
              title: DobryOps Homelab
              background: https://images.unsplash.com/photo-1502790671504-542ad42d5189?auto=format&fit=crop&w=2560&q=80
              cardBlur: md
              theme: dark
              color: slate
              headerStyle: boxed
              layout:
                Media:
                  style: row
                  columns: 4
                Automation:
                  style: row
                  columns: 4
                Infrastructure:
                  style: row
                  columns: 4
                Monitoring:
                  style: row
                  columns: 2

            bookmarks:
              - Developer:
                  - GitHub:
                      - abbr: GH
                        href: https://github.com

            services:
              - Media:
                  - Jellyfin:
                      href: https://${config.sops.placeholder."pangolin/resources/jellyfin/domain"}
                      description: Media streaming
                      icon: jellyfin.png
                  - Sonarr:
                      href: https://${config.sops.placeholder."pangolin/resources/sonarr/domain"}
                      description: TV automation
                      icon: sonarr.png
                  - Radarr:
                      href: https://${config.sops.placeholder."pangolin/resources/radarr/domain"}
                      description: Movie automation
                      icon: radarr.png
                  - Prowlarr:
                      href: https://${config.sops.placeholder."pangolin/resources/prowlarr/domain"}
                      description: Indexer management
                      icon: prowlarr.png
                  - Bazarr:
                      href: https://${config.sops.placeholder."pangolin/resources/bazarr/domain"}
                      description: Subtitles
                      icon: bazarr.png
                  - Jellyseerr:
                      href: https://${config.sops.placeholder."pangolin/resources/jellyseerr/domain"}
                      description: Request portal
                      icon: jellyseerr.png
                  - qBittorrent:
                      href: https://${config.sops.placeholder."pangolin/resources/qbittorrent/domain"}
                      description: Torrent client
                      icon: qbittorrent.png
                  - NZBGet:
                      href: https://${config.sops.placeholder."pangolin/resources/nzbget/domain"}
                      description: Usenet client
                      icon: nzbget.png

              - Automation:
                  - GitLab:
                      href: https://${config.sops.placeholder."pangolin/resources/gitlab/domain"}
                      description: Git & CI/CD
                      icon: gitlab.png
                  - ArgoCD:
                      href: https://${config.sops.placeholder."pangolin/resources/argocd/domain"}
                      description: GitOps
                      icon: argo-cd.png
                  - Ghost:
                      href: https://${config.sops.placeholder."pangolin/resources/ghost/domain"}
                      description: Blog
                      icon: ghost.png
                  - Reactive Resume:
                      href: https://${config.sops.placeholder."pangolin/resources/reactive_resume/domain"}
                      description: Resume builder
                      icon: reactive-resume.png

              - Infrastructure:
                  - Pi-hole:
                      href: https://${config.sops.placeholder."pangolin/resources/pihole/domain"}
                      description: DNS & ad blocking
                      icon: pi-hole.png
                  - MinIO:
                      href: https://${config.sops.placeholder."pangolin/resources/minio_console/domain"}
                      description: Object storage
                      icon: minio.png
                  - PostgreSQL:
                      href: https://${config.sops.placeholder."pangolin/resources/pgadmin/domain"}
                      description: Database admin
                      icon: pgadmin.png
                  - Registry:
                      href: https://${config.sops.placeholder."pangolin/resources/registry/domain"}
                      description: Container registry
                      icon: docker.png

              - Monitoring:
                  - Grafana:
                      href: https://${config.sops.placeholder."pangolin/resources/grafana/domain"}
                      description: Dashboards
                      icon: grafana.png
                  - Traefik:
                      href: https://${config.sops.placeholder."pangolin/resources/traefik_dashboard/domain"}
                      description: Ingress
                      icon: traefik.png

            widgets:
              - logo:
                  icon: https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/png/homepage.png
              - greeting:
                  text_size: xl
                  text: DobryOps Homelab
              - datetime:
                  text_size: l
                  format:
                    dateStyle: long
                    timeStyle: short
              - kubernetes:
                  cluster:
                    show: true
                    cpu: true
                    memory: true
                    showLabel: true
                    label: "cluster"
                  nodes:
                    show: true
                    cpu: true
                    memory: true
                    showLabel: true
              - resources:
                  cpu: true
                  memory: true

            kubernetes:
              mode: cluster
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/homepage.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
