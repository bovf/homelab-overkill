{ config, ... }:

{
  sops.templates."reactive-resume-ingress.yaml" = {
    content = ''
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: reactive-resume
        namespace: resume
        annotations:
          traefik.ingress.kubernetes.io/router.entrypoints: "web,websecure"
          traefik.ingress.kubernetes.io/router.middlewares: "resume-reactive-resume-headers@kubernetescrd"
          cert-manager.io/cluster-issuer: letsencrypt
      spec:
        ingressClassName: traefik
        rules:
          - host: "${config.sops.placeholder."pangolin/resources/reactive_resume/domain"}"
            http:
              paths:
                - path: /
                  pathType: Prefix
                  backend:
                    service:
                      name: reactive-resume
                      port:
                        number: 3000
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/reactive-resume-ingress.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
