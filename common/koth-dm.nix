{ config, lib, pkgs, ... }:

let cfg = config.services.koth-dm;
in {
  options.services.koth-dm = {
    enable = lib.mkEnableOption "KotH DM — second hermes-agent host integration (D&D Game-Master persona)";
    agent = {
      enable = lib.mkEnableOption "hermes-agent daemon (KotH DM) running as koth-dm";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.hermes-agent;
        defaultText = lib.literalExpression "pkgs.hermes-agent";
        description = "hermes-agent package; defaults to the overlay-provided uv2nix build.";
      };
      gatewayPort = lib.mkOption {
        type = lib.types.port;
        default = 7778;
      };
      gatewayBind = lib.mkOption {
        type = lib.types.str;
        default = "100.89.128.16";
      };
      soulFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = ./koth-dm-soul.md;
        description = "Path to SOUL.md — hermes auto-loads this as the agent's identity. Copied to /home/koth-dm/.hermes/SOUL.md on activation. Null disables deployment.";
      };
      campaignFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = ./koth-dm-campaign.md;
        description = "Path to CAMPAIGN.md — the campaign bible (world, factions, NPCs, hard rules). Symlinked into /home/koth-dm/.hermes/CAMPAIGN.md and used as restartTrigger. Null disables deployment.";
      };
      matrix = {
        enable = lib.mkEnableOption "Matrix adapter — bootstraps @koth-dm:<server> on Synapse";
        serverDomainSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "pangolin/resources/matrix/domain";
          description = "sops key holding the Matrix homeserver's public domain.";
        };
        userLocalpart = lib.mkOption {
          type = lib.types.str;
          default = "koth-dm";
          description = "Matrix bot user local-part (yields @<localpart>:<server>).";
        };
        displayName = lib.mkOption {
          type = lib.types.str;
          default = "KotH GM";
          description = "Display name set on the bot's matrix profile after registration.";
        };
        avatarImage = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = ./koth-dm.png;
          description = "Path to the bot's avatar image. Null skips avatar upload (bot will appear with no avatar — Matrix default).";
        };
        avatarMimeType = lib.mkOption {
          type = lib.types.str;
          default = "image/png";
          description = "MIME type of avatarImage (image/png, image/jpeg, etc.). Ignored when avatarImage is null.";
        };
        authorizedUsersSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "hermes/koth_dm_matrix_allowed_users";
          description = "sops key holding a CSV list of mxids allowed to command the bot. Null omits MATRIX_ALLOWED_USERS.";
        };
        allowedRoomsSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "hermes/koth_dm_matrix_allowed_rooms";
          description = "sops key holding a CSV list of Matrix room IDs the bot will respond in. Null omits MATRIX_ALLOWED_ROOMS.";
        };
        homeChannelChatIdSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "hermes/koth_dm_matrix_home_channel";
          description = "sops key holding a single Matrix room ID rendered as MATRIX_HOME_ROOM in koth-dm's .env. Silences hermes's 'No home channel' prompt.";
        };
        passwordSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "hermes/koth_dm_matrix_password";
          description = "sops key holding the bot user's matrix password.";
        };
        sharedSecretSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "matrix/synapse/registration_shared_secret";
          description = "sops key holding synapse's registration_shared_secret (shared with hale).";
        };
        synapseImage = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/element-hq/synapse:v1.153.0";
          description = "Synapse image used by the bootstrap Job.";
        };
      };
      skills.enable = lib.mkEnableOption "publish bundled koth-dm skills from common/koth-dm-skills/ into /home/koth-dm/.hermes/skills/";
      skills.dropBundled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run `hermes skills opt-out --remove --yes` as koth-dm on every service start. Writes a `.no-bundled-skills` marker so hermes stops seeding its built-in skill tree (devops/, software-development/, kanban-*, etc.) into koth-dm's profile, and removes any unmodified bundled skills currently on disk. Idempotent. Curated skills come exclusively from common/koth-dm-skills/.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      users.groups.koth-dm = { };
      users.users.koth-dm = {
        isSystemUser = true;
        group        = "koth-dm";
        description  = "KotH Dungeon Master (hermes-agent)";
        home         = "/home/koth-dm";
        createHome   = true;
        shell        = pkgs.bashInteractive;
        extraGroups  = [ "systemd-journal" ];
        openssh.authorizedKeys.keys =
          config.users.users.engineer.openssh.authorizedKeys.keys;
      };
    }

    (lib.mkIf (cfg.enable && cfg.agent.skills.enable) (
      let
        skillsDir = ./koth-dm-skills;
        skillNames = builtins.attrNames (builtins.readDir skillsDir);
      in {
        systemd.tmpfiles.rules = [
          "d /home/koth-dm/.hermes 0700 koth-dm koth-dm -"
          "d /home/koth-dm/.hermes/skills 0755 koth-dm koth-dm -"
        ] ++ map
          (n: "L+ /home/koth-dm/.hermes/skills/${n} - - - - ${skillsDir}/${n}")
          skillNames;
      }
    ))

    (lib.mkIf cfg.agent.enable {
      systemd.tmpfiles.rules = [
        "d /home/koth-dm/.hermes 0700 koth-dm koth-dm -"
      ] ++ lib.optionals (cfg.agent.soulFile != null) [
        "L+ /home/koth-dm/.hermes/SOUL.md - - - - ${cfg.agent.soulFile}"
        "h /home/koth-dm/.hermes/SOUL.md - koth-dm koth-dm - -"
      ] ++ lib.optionals (cfg.agent.campaignFile != null) [
        "L+ /home/koth-dm/.hermes/CAMPAIGN.md - - - - ${cfg.agent.campaignFile}"
        "h /home/koth-dm/.hermes/CAMPAIGN.md - koth-dm koth-dm - -"
      ];

      systemd.services."hermes-agent.koth-dm" = {
        description = "Hermes Agent (KotH GM)";
        restartTriggers =
          lib.optional (cfg.agent.soulFile != null) cfg.agent.soulFile
          ++ lib.optional (cfg.agent.campaignFile != null) cfg.agent.campaignFile;
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          HOME = "/home/koth-dm";
          HERMES_HOME = "/home/koth-dm/.hermes";
          HERMES_GATEWAY_HOST = cfg.agent.gatewayBind;
          HERMES_GATEWAY_PORT = toString cfg.agent.gatewayPort;
          PYTHONUNBUFFERED = "1";
        };
        serviceConfig = {
          User  = "koth-dm";
          Group = "koth-dm";
          WorkingDirectory = "/home/koth-dm";
          ExecStartPre = lib.optional cfg.agent.skills.dropBundled
            "${cfg.agent.package}/bin/hermes skills opt-out --remove --yes";
          ExecStart = "${cfg.agent.package}/bin/hermes gateway";
          Restart = "on-failure";
          RestartSec = 10;
          TimeoutStopSec = "240s";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ReadWritePaths = [ "/home/koth-dm" ];
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
        } // lib.optionalAttrs (cfg.agent.matrix.homeChannelChatIdSopsKey != null) {
          ${cfg.agent.matrix.homeChannelChatIdSopsKey} = { };
        };

        sops.templates."hermes-matrix-bootstrap-koth-dm-secret.yaml" = {
          content = ''
            apiVersion: v1
            kind: Secret
            metadata:
              name: hermes-matrix-bootstrap-koth-dm
              namespace: matrix
            type: Opaque
            stringData:
              bot_password: "${config.sops.placeholder.${cfg.agent.matrix.passwordSopsKey}}"
              shared_secret: "${config.sops.placeholder.${cfg.agent.matrix.sharedSecretSopsKey}}"
              server_name: "${config.sops.placeholder.${cfg.agent.matrix.serverDomainSopsKey}}"
          '';
          path  = "/var/lib/rancher/k3s/server/manifests/hermes-matrix-bootstrap-koth-dm-secret.yaml";
          owner = "root";
          group = "root";
          mode  = "0600";
        };

        systemd.tmpfiles.rules = [
          "d /home/koth-dm/.hermes 0700 koth-dm koth-dm -"
        ] ++ lib.optionals (cfg.agent.matrix.avatarImage != null) [
          "d /etc/koth-dm 0755 root root -"
          "C+ /etc/koth-dm/avatar.png 0444 root root - ${cfg.agent.matrix.avatarImage}"
        ];

        sops.templates."koth-dm-hermes-env" = {
          content = ''
            MATRIX_HOMESERVER=https://${config.sops.placeholder.${cfg.agent.matrix.serverDomainSopsKey}}
            MATRIX_USER_ID=@${cfg.agent.matrix.userLocalpart}:${config.sops.placeholder.${cfg.agent.matrix.serverDomainSopsKey}}
            MATRIX_PASSWORD=${config.sops.placeholder.${cfg.agent.matrix.passwordSopsKey}}
            MATRIX_ENCRYPTION=true
            ${lib.optionalString (cfg.agent.matrix.authorizedUsersSopsKey != null)
              "MATRIX_ALLOWED_USERS=${config.sops.placeholder.${cfg.agent.matrix.authorizedUsersSopsKey}}"}
            ${lib.optionalString (cfg.agent.matrix.allowedRoomsSopsKey != null)
              "MATRIX_ALLOWED_ROOMS=${config.sops.placeholder.${cfg.agent.matrix.allowedRoomsSopsKey}}"}
            ${lib.optionalString (cfg.agent.matrix.homeChannelChatIdSopsKey != null) ''
              MATRIX_HOME_ROOM=${config.sops.placeholder.${cfg.agent.matrix.homeChannelChatIdSopsKey}}
              MATRIX_HOME_ROOM_NAME=KotH Campaign
            ''}
          '';
          path  = "/home/koth-dm/.hermes/.env";
          owner = "koth-dm";
          group = "koth-dm";
          mode  = "0600";
          restartUnits = [ "hermes-agent.koth-dm.service" ];
        };

        services.k3s.manifests.hermes-matrix-bootstrap-koth-dm.content = {
          apiVersion = "batch/v1";
          kind = "Job";
          metadata = {
            name = "hermes-matrix-bootstrap-koth-dm";
            namespace = "matrix";
          };
          spec = {
            backoffLimit = 5;
            template.spec = {
              restartPolicy = "Never";
              volumes = lib.optional (cfg.agent.matrix.avatarImage != null) {
                name = "avatar";
                hostPath = {
                  path = "/etc/koth-dm/avatar.png";
                  type = "File";
                };
              };
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

                    ${lib.optionalString (cfg.agent.matrix.avatarImage != null) ''
                    MXC=$(curl -fsS -X POST \
                      "$SYNAPSE/_matrix/media/v3/upload?filename=koth-dm" \
                      -H "Authorization: Bearer $ACCESS_TOKEN" \
                      -H "Content-Type: $AVATAR_MIME" \
                      --data-binary "@/etc/koth-dm-avatar/avatar" \
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
                    ''}
                  ''
                ];
                env = [
                  { name = "BOT_USER";     value = cfg.agent.matrix.userLocalpart; }
                  { name = "DISPLAY_NAME"; value = cfg.agent.matrix.displayName; }
                  { name = "AVATAR_MIME";  value = cfg.agent.matrix.avatarMimeType; }
                  {
                    name = "BOT_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "hermes-matrix-bootstrap-koth-dm";
                      key  = "bot_password";
                    };
                  }
                  {
                    name = "SHARED_SECRET";
                    valueFrom.secretKeyRef = {
                      name = "hermes-matrix-bootstrap-koth-dm";
                      key  = "shared_secret";
                    };
                  }
                  {
                    name = "SERVER_NAME";
                    valueFrom.secretKeyRef = {
                      name = "hermes-matrix-bootstrap-koth-dm";
                      key  = "server_name";
                    };
                  }
                ];
                volumeMounts = lib.optional (cfg.agent.matrix.avatarImage != null) {
                  name = "avatar";
                  mountPath = "/etc/koth-dm-avatar/avatar";
                  readOnly = true;
                };
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
