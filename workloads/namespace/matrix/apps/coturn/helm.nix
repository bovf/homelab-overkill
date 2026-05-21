{ ... }:

{
  sops.templates."helm/coturn.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: coturn
        namespace: kube-system
      spec:
        repo: https://bjw-s-labs.github.io/helm-charts
        chart: app-template
        version: "4.6.2"
        targetNamespace: matrix
        createNamespace: false
        valuesContent: |
          defaultPodOptions:
            annotations:
              secret.reloader.stakater.com/reload: "coturn-config"

          controllers:
            main:
              containers:
                main:
                  image:
                    repository: docker.io/coturn/coturn
                    tag: "4.11.0"
                  command:
                    - turnserver
                    - -c
                    - /etc/coturn/turnserver.conf
                  probes:
                    liveness:
                      enabled: true
                      custom: true
                      spec:
                        tcpSocket:
                          port: 5349
                        initialDelaySeconds: 15
                        periodSeconds: 30
                    readiness:
                      enabled: true
                      custom: true
                      spec:
                        tcpSocket:
                          port: 5349
                        initialDelaySeconds: 10
                        periodSeconds: 10
                  resources:
                    requests:
                      cpu: 20m
                      memory: 32Mi
                    limits:
                      cpu: 500m
                      memory: 256Mi

          service:
            main:
              controller: main
              type: ClusterIP
              externalIPs:
                - "100.89.128.16"
              ports:
                turns:
                  port: 5349
                  protocol: TCP

          persistence:
            coturn-config:
              type: secret
              name: coturn-config
              globalMounts:
                - path: /etc/coturn/turnserver.conf
                  subPath: turnserver.conf
                  readOnly: true
            certs:
              type: secret
              name: turn-dobryops-com-tls
              globalMounts:
                - path: /certs
                  readOnly: true
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/coturn.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
