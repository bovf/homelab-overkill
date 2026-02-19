{ config, ... }:

{
  sops.templates."traefik-dashboard-ingress.yaml" = {
    content = ''
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: traefik-dashboard
        namespace: kube-system
        annotations:
          kubernetes.io/ingress.class: traefik
          traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
      spec:
        rules:
          - host: "${config.sops.placeholder."pangolin/resources/traefik_dashboard/domain"}"
            http:
              paths:
                - path: /dashboard
                  pathType: Prefix
                  backend:
                    service:
                      name: traefik-dashboard
                      port:
                        number: 8080
                - path: /api
                  pathType: Prefix
                  backend:
                    service:
                      name: traefik-dashboard
                      port:
                        number: 8080
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/traefik-dashboard-ingress.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
