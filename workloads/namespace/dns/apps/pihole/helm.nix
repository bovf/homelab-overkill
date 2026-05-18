{ config, lib, ... }:

let
  inherit (lib) mapAttrsToList concatStringsSep;

  hostEntries = mapAttrsToList
    (_: r: "${r.ip} ${r.host}")
    config.workloads.localDnsRecords;
  dnsHosts = concatStringsSep ";" hostEntries;
in
{
  sops.templates."helm/pihole.yaml" = {
    content = ''
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: pihole
        namespace: kube-system
      spec:
        repo: https://mojo2600.github.io/pihole-kubernetes/
        chart: pihole
        version: "2.31.0"
        targetNamespace: dns
        createNamespace: false
        valuesContent: |
          replicaCount: 1

          image:
            repository: pihole/pihole
            tag: "2025.02.2"
            pullPolicy: IfNotPresent

          strategy:
            type: RollingUpdate

          serviceType: ClusterIP

          serviceWeb:
            type: ClusterIP

          ingress:
            enabled: true
            ingressClassName: traefik
            annotations:
              traefik.ingress.kubernetes.io/router.entrypoints: web,websecure
              traefik.ingress.kubernetes.io/router.middlewares: dns-pihole-headers@kubernetescrd
            hosts:
              - ${config.sops.placeholder."pangolin/resources/pihole/domain"}
            tls: false

          persistentVolumeClaim:
            enabled: true
            storageClassName: local-path
            accessMode: ReadWriteOnce
            size: 2Gi

          serviceDns:
            # MetalLB requires matching `allow-shared-ip` on both TCP
            # and UDP Services to permit them to share an IP.
            mixedService: false
            type: LoadBalancer
            loadBalancerIP: 192.168.2.2
            annotations:
              metallb.io/allow-shared-ip: "pihole-dns"
            # Local preserves the real client IP in the query log.
            # Earlier this looked broken cross-subnet; the actual cause
            # was dnsmasq's listeningMode=LOCAL rejecting "non-local"
            # sources. With listeningMode=ALL the rejection is gone, and
            # UDP DNS tolerates the asymmetric reply path.
            externalTrafficPolicy: Local

          serviceDhcp:
            enabled: false

          # Bumped from 80 to clear the tunnel-side externalIPs port
          # collision with whoami/pgadmin/argocd.
          webHttp: "8089"
          webHttps: "443"

          resources:
            limits:
              cpu: 500m
              memory: 512Mi
            requests:
              cpu: 100m
              memory: 256Mi

          admin:
            existingSecret: pihole-web-password
            passwordKey: password

          # Chart ignores a top-level `env:` key; only extraEnvVars /
          # extraEnvVarsSecret / ftl are wired through.
          extraEnvVars:
            TZ: "Europe/Sofia"
            FTLCONF_query_logging: "true"
            FTLCONF_database_maxdbdays: "7"
            FTLCONF_dns_hosts: "${dnsHosts}"
            # Accept queries from any source — required so cluster pods
            # (10.42/16) and LAN clients on 192.168.1/24 can both query
            # the .2.2 listener. Default LOCAL rejects with "ignoring
            # query from non-local network".
            FTLCONF_dns_listeningMode: "ALL"
            # Cloudflare benchmarked ~4x faster than Google from this LAN.
            FTLCONF_dns_upstreams: "1.1.1.1;1.0.0.1"

          # Blocks DNS-over-HTTPS endpoint hostnames so DoH-by-default
          # browsers fall back to system DNS (= pihole). Doesn't catch
          # apps with hardcoded DoH IPs or iCloud Private Relay.
          adlists:
            - https://raw.githubusercontent.com/dibdot/DoH-IP-blocklists/master/doh-domains_overall.txt

          podDnsConfig:
            enabled: true
            policy: "None"
            nameservers:
              - 8.8.8.8
              - 8.8.4.4

          podSecurityContext:
            fsGroup: 999
            runAsUser: 999
            runAsNonRoot: true

          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              add:
                - NET_BIND_SERVICE
              drop:
                - ALL
            readOnlyRootFilesystem: false

          nodeSelector: {}
          tolerations: []
          affinity: {}
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/pihole.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
