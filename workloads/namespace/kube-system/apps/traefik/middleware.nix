{ config, ... }:

{
  sops.templates."traefik-dashboard-redirect.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: Middleware
      metadata:
        name: dashboard-root-redirect
        namespace: kube-system
      spec:
        redirectRegex:
          regex: "^https?://${config.sops.placeholder."pangolin/resources/traefik_dashboard/domain"}/?$"
          replacement: "https://${config.sops.placeholder."pangolin/resources/traefik_dashboard/domain"}/dashboard/"
          permanent: true
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/traefik-dashboard-redirect.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  sops.templates."traefik-dashboard-ingressroute.yaml" = {
    content = ''
      apiVersion: traefik.io/v1alpha1
      kind: IngressRoute
      metadata:
        name: traefik-dashboard
        namespace: kube-system
        labels:
          app.kubernetes.io/name: traefik-dashboard
          app.kubernetes.io/instance: traefik
      spec:
        entryPoints:
          - web
          - websecure
        routes:
          - match: "Host(`${config.sops.placeholder."pangolin/resources/traefik_dashboard/domain"}`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))"
            kind: Rule
            services:
              - kind: TraefikService
                name: api@internal
          - match: "Host(`${config.sops.placeholder."pangolin/resources/traefik_dashboard/domain"}`) && Path(`/`)"
            kind: Rule
            middlewares:
              - name: dashboard-root-redirect
            services:
              - kind: TraefikService
                name: api@internal
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/traefik-dashboard-ingressroute.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
