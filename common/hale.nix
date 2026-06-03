{ config, lib, pkgs, ... }:

let cfg = config.services.hale;
in {
  options.services.hale = {
    enable = lib.mkEnableOption "Saxton Hale — hermes-agent host integration";
    kubeAccess.enable = lib.mkEnableOption "read-only kubeconfig for hale from the hermes-observer ServiceAccount";
    agent = {
      enable = lib.mkEnableOption "hermes-agent daemon (Saxton Hale) running as hale";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.hermes-agent;
        defaultText = lib.literalExpression "pkgs.hermes-agent";
        description = "hermes-agent package; defaults to the overlay-provided uv2nix build.";
      };
      gatewayPort = lib.mkOption {
        type = lib.types.port;
        default = 7777;
      };
      gatewayBind = lib.mkOption {
        type = lib.types.str;
        default = "100.89.128.16";
      };
      matrix = {
        enable = lib.mkEnableOption "Matrix adapter — bootstraps @<localpart>:<server> on Synapse";
        serverDomainSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "pangolin/resources/matrix/domain";
          description = "sops key holding the Matrix homeserver's public domain.";
        };
        userLocalpart = lib.mkOption {
          type = lib.types.str;
          default = "hale";
          description = "Matrix bot user local-part (yields @<localpart>:<server>).";
        };
        displayName = lib.mkOption {
          type = lib.types.str;
          default = "Saxton Hale";
          description = "Display name set on the bot's matrix profile after registration.";
        };
        avatarImage = lib.mkOption {
          type = lib.types.path;
          default = ./hale.png;
          description = "Path to the bot's avatar image. Uploaded to synapse media and set as avatar_url.";
        };
        avatarMimeType = lib.mkOption {
          type = lib.types.str;
          default = "image/png";
          description = "MIME type of avatarImage (image/png, image/jpeg, etc.).";
        };
        authorizedUsersSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "hermes/matrix_allowed_users";
          description = "sops key holding a CSV list of mxids allowed to command the bot. Null omits MATRIX_ALLOWED_USERS (hermes default behaviour applies).";
        };
        allowedRoomsSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "hermes/matrix_allowed_rooms";
          description = "sops key holding a CSV list of Matrix room IDs the bot will respond in. Null omits MATRIX_ALLOWED_ROOMS (bot responds in any room it's been invited to). When set, combines with authorizedUsersSopsKey via AND — both checks must pass.";
        };
        passwordSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "hermes/matrix_bot_password";
          description = "sops key holding the bot user's matrix password (you provision this).";
        };
        sharedSecretSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "matrix/synapse/registration_shared_secret";
          description = "sops key holding synapse's registration_shared_secret.";
        };
        synapseImage = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/element-hq/synapse:v1.153.0";
          description = "Synapse image used by the bootstrap Job (only register_new_matrix_user is invoked).";
        };
      };
      media.enable = lib.mkEnableOption "expose radarr/sonarr/sportarr/prowlarr/bazarr/qbittorrent/nzbget credentials in hale's .env";
      skills.enable = lib.mkEnableOption "publish bundled hale skills from common/hale-skills/ into /home/hale/.hermes/skills/";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      users.groups.hale = { };
      users.users.hale = {
        isSystemUser = true;
        group        = "hale";
        description  = "Saxton Hale";
        home         = "/home/hale";
        createHome   = true;
        shell        = pkgs.bashInteractive;
        extraGroups  = [ "systemd-journal" ];
        openssh.authorizedKeys.keys =
          config.users.users.engineer.openssh.authorizedKeys.keys;
      };

      environment.systemPackages = [ cfg.agent.package ];
    }

    (lib.mkIf cfg.kubeAccess.enable {
      users.groups.hale-kube = { };
      users.users.hale.extraGroups = [ "hale-kube" ];

      systemd.tmpfiles.rules = [
        "d /etc/hale 0755 root root -"
      ];

      environment.etc."profile.d/hale-kubeconfig.sh".text = ''
        if [ "$USER" = "hale" ] && [ -r /etc/hale/kubeconfig ]; then
          export KUBECONFIG=/etc/hale/kubeconfig
        fi
      '';

      systemd.services.hale-kubeconfig = {
        description = "Render hale's read-only kubeconfig from hermes-observer SA";
        after = [ "k3s.service" ];
        wants = [ "k3s.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.kubectl pkgs.coreutils ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "hale-render-kubeconfig" ''
            set -eu
            NS=hermes
            SECRET=hermes-observer-token
            DEST=/etc/hale/kubeconfig
            KCONF=/etc/rancher/k3s/k3s.yaml

            for i in $(seq 1 60); do
              TOKEN_B64=$(KUBECONFIG=$KCONF kubectl -n $NS get secret $SECRET -o jsonpath='{.data.token}' 2>/dev/null || true)
              [ -n "$TOKEN_B64" ] && break
              sleep 2
            done
            [ -n "$TOKEN_B64" ] || { echo "no token on $NS/$SECRET after 120s" >&2; exit 1; }

            CA_B64=$(KUBECONFIG=$KCONF kubectl -n $NS get secret $SECRET -o jsonpath='{.data.ca\.crt}')
            SERVER=$(KUBECONFIG=$KCONF kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
            TOKEN=$(printf %s "$TOKEN_B64" | base64 -d)

            TMP=$(mktemp)
            cat > "$TMP" <<EOF
            apiVersion: v1
            kind: Config
            clusters:
            - name: engineer-k3s
              cluster:
                server: $SERVER
                certificate-authority-data: $CA_B64
            contexts:
            - name: hale@engineer-k3s
              context:
                cluster: engineer-k3s
                user: hale
                namespace: default
            current-context: hale@engineer-k3s
            users:
            - name: hale
              user:
                token: $TOKEN
            EOF

            install -o root -g hale-kube -m 0640 "$TMP" "$DEST"
            rm -f "$TMP"
          '';
        };
      };

      services.k3s.manifests.hermes-ns.content = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata.name = "hermes";
      };

      services.k3s.manifests.hermes-observer-sa.content = {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
          name = "hermes-observer";
          namespace = "hermes";
        };
      };

      services.k3s.manifests.hermes-observer-cr.content = {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "ClusterRole";
        metadata.name = "hermes-observer";
        rules = [
          {
            apiGroups = [ "" ];
            resources = [
              "pods" "pods/log" "pods/status"
              "services" "endpoints" "configmaps"
              "events" "nodes" "namespaces"
              "persistentvolumeclaims" "persistentvolumes"
              "replicationcontrollers"
            ];
            verbs = [ "get" "list" "watch" ];
          }
          {
            apiGroups = [ "apps" ];
            resources = [ "deployments" "statefulsets" "daemonsets" "replicasets" ];
            verbs = [ "get" "list" "watch" ];
          }
          {
            apiGroups = [ "batch" ];
            resources = [ "jobs" "cronjobs" ];
            verbs = [ "get" "list" "watch" ];
          }
          {
            apiGroups = [ "networking.k8s.io" ];
            resources = [ "ingresses" "networkpolicies" ];
            verbs = [ "get" "list" "watch" ];
          }
          {
            apiGroups = [ "discovery.k8s.io" ];
            resources = [ "endpointslices" ];
            verbs = [ "get" "list" "watch" ];
          }
          {
            apiGroups = [ "events.k8s.io" ];
            resources = [ "events" ];
            verbs = [ "get" "list" "watch" ];
          }
        ];
      };

      services.k3s.manifests.hermes-observer-crb.content = {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "ClusterRoleBinding";
        metadata.name = "hermes-observer";
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "hermes-observer";
        };
        subjects = [{
          kind = "ServiceAccount";
          name = "hermes-observer";
          namespace = "hermes";
        }];
      };

      services.k3s.manifests.hermes-observer-token.content = {
        apiVersion = "v1";
        kind = "Secret";
        type = "kubernetes.io/service-account-token";
        metadata = {
          name = "hermes-observer-token";
          namespace = "hermes";
          annotations."kubernetes.io/service-account.name" = "hermes-observer";
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.agent.skills.enable) (
      let
        skillsDir = ./hale-skills;
        skillNames = builtins.attrNames (builtins.readDir skillsDir);
      in {
        systemd.tmpfiles.rules = [
          "d /home/hale/.hermes 0700 hale hale -"
          "d /home/hale/.hermes/skills 0755 hale hale -"
        ] ++ map
          (n: "L+ /home/hale/.hermes/skills/${n} - - - - ${skillsDir}/${n}")
          skillNames;
      }
    ))

    (lib.mkIf cfg.agent.enable {
      systemd.services.hermes-agent = {
        description = "Hermes Agent (Saxton Hale)";
        after = [ "network-online.target" ]
          ++ lib.optional cfg.kubeAccess.enable "hale-kubeconfig.service";
        wants = [ "network-online.target" ];
        requires = lib.optional cfg.kubeAccess.enable "hale-kubeconfig.service";
        wantedBy = [ "multi-user.target" ];
        environment = {
          HOME = "/home/hale";
          HERMES_GATEWAY_HOST = cfg.agent.gatewayBind;
          HERMES_GATEWAY_PORT = toString cfg.agent.gatewayPort;
          PYTHONUNBUFFERED = "1";
        } // lib.optionalAttrs cfg.kubeAccess.enable {
          KUBECONFIG = "/etc/hale/kubeconfig";
        };
        serviceConfig = {
          User  = "hale";
          Group = "hale";
          WorkingDirectory = "/home/hale";
          ExecStart = "${cfg.agent.package}/bin/hermes gateway";
          Restart = "on-failure";
          RestartSec = 10;
          TimeoutStopSec = "240s";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ReadWritePaths = [ "/home/hale" ];
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
          RestrictNamespaces = true;
          LockPersonality = true;
          CapabilityBoundingSet = "";
          AmbientCapabilities = "";
        };
      };
    })

    (lib.mkIf (cfg.enable && cfg.agent.matrix.enable) {
        nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];

        sops.secrets = {
          ${cfg.agent.matrix.passwordSopsKey} = { };
          ${cfg.agent.matrix.sharedSecretSopsKey} = { };
          ${cfg.agent.matrix.serverDomainSopsKey} = { };
        } // lib.optionalAttrs (cfg.agent.matrix.authorizedUsersSopsKey != null) {
          ${cfg.agent.matrix.authorizedUsersSopsKey} = { };
        } // lib.optionalAttrs (cfg.agent.matrix.allowedRoomsSopsKey != null) {
          ${cfg.agent.matrix.allowedRoomsSopsKey} = { };
        } // lib.optionalAttrs cfg.agent.media.enable {
          "hermes/radarr_api_key"       = { };
          "hermes/sonarr_api_key"       = { };
          "hermes/sportarr_api_key"     = { };
          "hermes/prowlarr_api_key"     = { };
          "hermes/bazarr_api_key"       = { };
          "hermes/qbittorrent_username" = { };
          "hermes/qbittorrent_password" = { };
          "hermes/nzbget_hale_username" = { };
          "hermes/nzbget_hale_password" = { };
        };

        sops.templates."hermes-matrix-bootstrap-secret.yaml" = {
          content = ''
            apiVersion: v1
            kind: Secret
            metadata:
              name: hermes-matrix-bootstrap
              namespace: matrix
            type: Opaque
            stringData:
              bot_password: "${config.sops.placeholder.${cfg.agent.matrix.passwordSopsKey}}"
              shared_secret: "${config.sops.placeholder.${cfg.agent.matrix.sharedSecretSopsKey}}"
              server_name: "${config.sops.placeholder.${cfg.agent.matrix.serverDomainSopsKey}}"
          '';
          path  = "/var/lib/rancher/k3s/server/manifests/hermes-matrix-bootstrap-secret.yaml";
          owner = "root";
          group = "root";
          mode  = "0600";
        };

        systemd.tmpfiles.rules = [
          "d /etc/hale 0755 root root -"
          "C+ /etc/hale/avatar.png 0444 root root - ${cfg.agent.matrix.avatarImage}"
          "d /home/hale/.hermes 0700 hale hale -"
        ];

        sops.templates."hale-hermes-env" = {
          content = ''
            MATRIX_HOMESERVER=https://${config.sops.placeholder.${cfg.agent.matrix.serverDomainSopsKey}}
            MATRIX_USER_ID=@${cfg.agent.matrix.userLocalpart}:${config.sops.placeholder.${cfg.agent.matrix.serverDomainSopsKey}}
            MATRIX_PASSWORD=${config.sops.placeholder.${cfg.agent.matrix.passwordSopsKey}}
            MATRIX_ENCRYPTION=true
            ${lib.optionalString (cfg.agent.matrix.authorizedUsersSopsKey != null)
              "MATRIX_ALLOWED_USERS=${config.sops.placeholder.${cfg.agent.matrix.authorizedUsersSopsKey}}"}
            ${lib.optionalString (cfg.agent.matrix.allowedRoomsSopsKey != null)
              "MATRIX_ALLOWED_ROOMS=${config.sops.placeholder.${cfg.agent.matrix.allowedRoomsSopsKey}}"}
            ${lib.optionalString cfg.agent.media.enable ''
              RADARR_URL=http://radarr.media.svc.cluster.local:7878
              RADARR_API_KEY=${config.sops.placeholder."hermes/radarr_api_key"}
              SONARR_URL=http://sonarr.media.svc.cluster.local:8989
              SONARR_API_KEY=${config.sops.placeholder."hermes/sonarr_api_key"}
              SPORTARR_URL=http://sportarr.media.svc.cluster.local:8989
              SPORTARR_API_KEY=${config.sops.placeholder."hermes/sportarr_api_key"}
              PROWLARR_URL=http://prowlarr.media.svc.cluster.local:9696
              PROWLARR_API_KEY=${config.sops.placeholder."hermes/prowlarr_api_key"}
              BAZARR_URL=http://bazarr.media.svc.cluster.local:6767
              BAZARR_API_KEY=${config.sops.placeholder."hermes/bazarr_api_key"}
              QBITTORRENT_URL=http://qbittorrent.media.svc.cluster.local:8080
              QBITTORRENT_USERNAME=${config.sops.placeholder."hermes/qbittorrent_username"}
              QBITTORRENT_PASSWORD=${config.sops.placeholder."hermes/qbittorrent_password"}
              NZBGET_URL=http://nzbget.media.svc.cluster.local:6789
              NZBGET_USERNAME=${config.sops.placeholder."hermes/nzbget_hale_username"}
              NZBGET_PASSWORD=${config.sops.placeholder."hermes/nzbget_hale_password"}
            ''}
          '';
          path  = "/home/hale/.hermes/.env";
          owner = "hale";
          group = "hale";
          mode  = "0600";
          restartUnits = [ "hermes-agent.service" ];
        };

        services.k3s.manifests.hermes-matrix-bootstrap.content = {
          apiVersion = "batch/v1";
          kind = "Job";
          metadata = {
            name = "hermes-matrix-bootstrap";
            namespace = "matrix";
          };
          spec = {
            backoffLimit = 5;
            template.spec = {
              restartPolicy = "Never";
              volumes = [{
                name = "avatar";
                hostPath = {
                  path = "/etc/hale/avatar.png";
                  type = "File";
                };
              }];
              containers = [{
                name = "register";
                image = cfg.agent.matrix.synapseImage;
                command = [ "bash" ];
                args = [
                  "-ec"
                  ''
                    set -o pipefail
                    SYNAPSE=http://synapse.matrix.svc.cluster.local:8008

                    until curl -fsS "$SYNAPSE/_matrix/client/versions" >/dev/null 2>&1; do
                      echo "waiting for synapse..."
                      sleep 3
                    done

                    OUT=$(register_new_matrix_user \
                      -u "$BOT_USER" -p "$BOT_PASSWORD" --no-admin \
                      -k "$SHARED_SECRET" \
                      "$SYNAPSE" 2>&1) || true
                    echo "$OUT"
                    echo "$OUT" | grep -qE 'Success|User ID already taken|already exists' \
                      || { echo "register failed unexpectedly" >&2; exit 1; }

                    LOGIN_PAYLOAD=$(python3 -c '
                    import os, json
                    print(json.dumps({
                        "type": "m.login.password",
                        "identifier": {"type": "m.id.user", "user": os.environ["BOT_USER"]},
                        "password": os.environ["BOT_PASSWORD"],
                    }))')
                    ACCESS_TOKEN=$(curl -fsS -X POST "$SYNAPSE/_matrix/client/v3/login" \
                      -H 'Content-Type: application/json' \
                      -d "$LOGIN_PAYLOAD" \
                      | python3 -c 'import sys, json; print(json.load(sys.stdin)["access_token"])')

                    DN_PAYLOAD=$(python3 -c '
                    import os, json
                    print(json.dumps({"displayname": os.environ["DISPLAY_NAME"]}))')
                    curl -fsS -X PUT \
                      "$SYNAPSE/_matrix/client/v3/profile/@$BOT_USER:$SERVER_NAME/displayname" \
                      -H "Authorization: Bearer $ACCESS_TOKEN" \
                      -H 'Content-Type: application/json' \
                      -d "$DN_PAYLOAD"
                    echo "displayname set to '$DISPLAY_NAME' for @$BOT_USER:$SERVER_NAME"

                    MXC=$(curl -fsS -X POST \
                      "$SYNAPSE/_matrix/media/v3/upload?filename=hale" \
                      -H "Authorization: Bearer $ACCESS_TOKEN" \
                      -H "Content-Type: $AVATAR_MIME" \
                      --data-binary "@/etc/hale-avatar/avatar" \
                      | python3 -c 'import sys, json; print(json.load(sys.stdin)["content_uri"])')
                    AV_PAYLOAD=$(MXC="$MXC" python3 -c '
                    import os, json
                    print(json.dumps({"avatar_url": os.environ["MXC"]}))')
                    curl -fsS -X PUT \
                      "$SYNAPSE/_matrix/client/v3/profile/@$BOT_USER:$SERVER_NAME/avatar_url" \
                      -H "Authorization: Bearer $ACCESS_TOKEN" \
                      -H 'Content-Type: application/json' \
                      -d "$AV_PAYLOAD"
                    echo "avatar_url set to $MXC for @$BOT_USER:$SERVER_NAME"
                  ''
                ];
                env = [
                  { name = "BOT_USER";     value = cfg.agent.matrix.userLocalpart; }
                  { name = "DISPLAY_NAME"; value = cfg.agent.matrix.displayName; }
                  { name = "AVATAR_MIME";  value = cfg.agent.matrix.avatarMimeType; }
                  {
                    name = "BOT_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "hermes-matrix-bootstrap";
                      key  = "bot_password";
                    };
                  }
                  {
                    name = "SHARED_SECRET";
                    valueFrom.secretKeyRef = {
                      name = "hermes-matrix-bootstrap";
                      key  = "shared_secret";
                    };
                  }
                  {
                    name = "SERVER_NAME";
                    valueFrom.secretKeyRef = {
                      name = "hermes-matrix-bootstrap";
                      key  = "server_name";
                    };
                  }
                ];
                volumeMounts = [{
                  name = "avatar";
                  mountPath = "/etc/hale-avatar/avatar";
                  readOnly = true;
                }];
                resources = {
                  requests = { cpu = "50m";  memory = "128Mi"; };
                  limits   = { cpu = "500m"; memory = "256Mi"; };
                };
              }];
            };
          };
        };
      }
    )
  ]);
}
