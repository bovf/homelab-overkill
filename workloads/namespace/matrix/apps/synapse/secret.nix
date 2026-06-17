{config, ...}: let
  matrixDomain = config.sops.placeholder."pangolin/resources/matrix/domain";
  lkJwtDomain = config.sops.placeholder."pangolin/resources/livekit_jwt/domain";
in {
  # Full Synapse config + server signing key, rendered on the node so no
  # secret ever lands in git. The initContainer in helm.nix copies these
  # into the /data PVC on every pod start.
  sops.templates."matrix/synapse-config.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: synapse-config
        namespace: matrix
      type: Opaque
      stringData:
        homeserver.yaml: |
          server_name: "${matrixDomain}"
          public_baseurl: "https://${matrixDomain}/"
          pid_file: /data/homeserver.pid
          signing_key_path: /data/signing.key
          log_config: /data/log.config
          serve_server_wellknown: true

          listeners:
            - port: 8008
              tls: false
              type: http
              x_forwarded: true
              bind_addresses: ['0.0.0.0']
              resources:
                - names: [client, federation]
                  compress: false

          database:
            name: psycopg2
            args:
              user: synapse
              password: "${config.sops.placeholder."database/postgres/synapse/password"}"
              dbname: synapse
              host: postgresql.database.svc.cluster.local
              port: 5432
              cp_min: 5
              cp_max: 10

          media_store_path: /data/media
          max_upload_size: 100M

          # Purge cached remote media after 90d to bound /data/media growth.
          # Local uploads are kept (no local_media_lifetime) so chat history
          # never loses its attachments.
          media_retention:
            remote_media_lifetime: 90d

          # Private homeserver: registration is closed (admins create
          # accounts via register_new_matrix_user, which uses the shared
          # secret below) and federation is restricted to an explicit
          # whitelist of peer homeservers.
          enable_registration: false
          registration_shared_secret: "${config.sops.placeholder."matrix/synapse/registration_shared_secret"}"
          report_stats: false
          federation_domain_whitelist:
            - matrix.kedarlab.com
            - matrix.org
          trusted_key_servers: []
          suppress_key_server_warning: true

          macaroon_secret_key: "${config.sops.placeholder."matrix/synapse/macaroon_secret_key"}"
          form_secret: "${config.sops.placeholder."matrix/synapse/form_secret"}"

          # Element Call / MatrixRTC. Synapse 1.153+ has a first-class
          # matrix_rtc section; it advertises the configured LiveKit auth
          # service to compatible clients via /.well-known/matrix/client.
          # Keep the explicit well-known key too for older clients.
          matrix_rtc:
            transports:
              - type: livekit
                livekit_service_url: "https://${lkJwtDomain}"
          extra_well_known_client_content:
            "org.matrix.msc4143.rtc_foci":
              - type: "livekit"
                livekit_service_url: "https://${lkJwtDomain}"
        log.config: |
          version: 1
          formatters:
            precise:
              format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s - %(message)s'
          handlers:
            console:
              class: logging.StreamHandler
              formatter: precise
          loggers:
            synapse.storage.SQL:
              level: INFO
          root:
            level: INFO
            handlers: [console]
          disable_existing_loggers: false
        signing.key: |
          ${config.sops.placeholder."matrix/synapse/signing_key"}
    '';
    path = "/var/lib/rancher/k3s/server/manifests/synapse-config.yaml";
    owner = "root";
    group = "root";
    mode = "0644";
  };
}
