{ config, ... }:

{
  # turnserver.conf. Only the TLS port (5349) is ever exposed via Pangolin;
  # the UDP relay range stays cluster-internal. Working media path is
  # relay<->relay internal to coturn (each client tunnels media over its
  # own TLS connection) — see pangolin-blueprint.nix for the rationale.
  sops.templates."matrix/coturn-config.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: coturn-config
        namespace: matrix
      type: Opaque
      stringData:
        turnserver.conf: |
          listening-port=3478
          tls-listening-port=5349
          fingerprint
          use-auth-secret
          static-auth-secret=${config.sops.placeholder."matrix/turn_shared_secret"}
          realm=${config.sops.placeholder."pangolin/resources/matrix/domain"}
          cert=/certs/tls.crt
          pkey=/certs/tls.key
          # Relay range — internal only, never added as a Pangolin resource.
          min-port=49152
          max-port=49200
          no-tlsv1
          no-tlsv1_1
          no-cli
          pidfile=/tmp/turnserver.pid
          log-file=stdout
          simple-log
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/coturn-config.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };
}
