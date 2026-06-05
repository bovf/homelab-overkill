{ config, lib, pkgs, ... }:

let
  cfg = config.services.ms-researcher;

  # MCP server packages — one Python derivation per server, built from
  # common/mcps/<name>/server.py with httpx as the only runtime dep.
  mcpPackages = import ./mcps { inherit pkgs; };

  mcpServersJson = pkgs.writeText "ms-researcher-mcp.json" (builtins.toJSON {
    mcpServers = lib.listToAttrs (map (n: {
      name = n;
      value = {
        command = "${mcpPackages.${n}}/bin/mcp-${n}";
        args = [ ];
      };
    }) cfg.agent.mcps);
  });

  kbRoot       = "/var/lib/ms-researcher/kb";
  kbReadmeSrc  = ./ms-researcher-kb-readme.md;
in {
  options.services.ms-researcher = {
    enable = lib.mkEnableOption "MS researcher — hermes-agent host integration (knowledgebase-focused)";

    agent = {
      enable = lib.mkEnableOption "hermes-agent daemon (MS researcher) running as ms-researcher";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.hermes-agent;
        defaultText = lib.literalExpression "pkgs.hermes-agent";
        description = "hermes-agent package; defaults to the overlay-provided uv2nix build.";
      };
      gatewayPort = lib.mkOption {
        type = lib.types.port;
        default = 7779;
      };
      gatewayBind = lib.mkOption {
        type = lib.types.str;
        default = "100.89.128.16";
      };
      soulFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = ./ms-researcher-soul.md;
        description = "Path to SOUL.md — hermes auto-loads this as the agent's identity (slot #1 in the system prompt). Copied to /home/ms-researcher/.hermes/SOUL.md on activation. Null disables deployment.";
      };
      mcps = lib.mkOption {
        type = lib.types.listOf (lib.types.enum (lib.attrNames mcpPackages));
        default = [ ];
        example = [ "pubmed" "searxng" "crossref" ];
        description = "MCP server names from common/mcps/ to wire into ~/.hermes/mcp.json.";
      };
      kb = {
        enable = lib.mkEnableOption "knowledgebase bind-mount + initial directory tree at /var/lib/ms-researcher/kb";
        path = lib.mkOption {
          type = lib.types.str;
          default = kbRoot;
          description = "Host directory holding the Logseq-browseable kb tree. Bind-mounted into /home/ms-researcher/kb.";
        };
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
          default = "ms-researcher";
          description = "Matrix bot user local-part (yields @<localpart>:<server>).";
        };
        displayName = lib.mkOption {
          type = lib.types.str;
          default = "MS Research Librarian";
          description = "Display name set on the bot's matrix profile after registration.";
        };
        avatarImage = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to the bot's avatar image. Null skips the avatar upload step entirely.";
        };
        avatarMimeType = lib.mkOption {
          type = lib.types.str;
          default = "image/png";
          description = "MIME type of avatarImage (image/png, image/jpeg, etc.).";
        };
        authorizedUsersSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "hermes/ms_researcher_matrix_allowed_users";
          description = "sops key holding a CSV list of mxids allowed to command the bot. Null omits MATRIX_ALLOWED_USERS.";
        };
        allowedRoomsSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "hermes/ms_researcher_matrix_allowed_rooms";
          description = "sops key holding a CSV list of Matrix room IDs the bot will respond in. Null omits MATRIX_ALLOWED_ROOMS.";
        };
        homeChannelChatIdSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "hermes/ms_researcher_matrix_home_channel";
          description = "sops key holding a single Matrix room ID rendered as MATRIX_HOME_ROOM in the agent's .env. Used by the weekly digest cron to deliver into the shared room.";
        };
        passwordSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "hermes/ms_researcher_matrix_password";
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
      searxngDomainSopsKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "pangolin/resources/search/domain";
        description = "sops key holding the SearXNG host. Rendered as SEARXNG_DOMAIN in the agent's .env so the searxng MCP can target it. Null disables the wiring.";
      };
      skills.enable = lib.mkEnableOption "publish bundled skills from common/ms-researcher-skills/ into /home/ms-researcher/.hermes/skills/";
      cron = {
        enable = lib.mkEnableOption "publish bundled cron jobs from common/ms-researcher-cron/ into /home/ms-researcher/.hermes/cron/";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      users.groups.ms-researcher = { };
      users.users.ms-researcher = {
        isSystemUser = true;
        group        = "ms-researcher";
        description  = "MS Researcher (hermes-agent)";
        home         = "/home/ms-researcher";
        createHome   = true;
        shell        = pkgs.bashInteractive;
        extraGroups  = [ "systemd-journal" ];
        openssh.authorizedKeys.keys =
          config.users.users.engineer.openssh.authorizedKeys.keys;
      };

      environment.systemPackages = [ cfg.agent.package ];
    }

    (lib.mkIf (cfg.enable && cfg.agent.skills.enable) (
      let
        skillsDir = ./ms-researcher-skills;
        skillNames = builtins.attrNames (builtins.readDir skillsDir);
      in {
        systemd.tmpfiles.rules = [
          "d /home/ms-researcher/.hermes 0700 ms-researcher ms-researcher -"
          "d /home/ms-researcher/.hermes/skills 0755 ms-researcher ms-researcher -"
        ] ++ map
          (n: "L+ /home/ms-researcher/.hermes/skills/${n} - - - - ${skillsDir}/${n}")
          skillNames;
      }
    ))

    (lib.mkIf (cfg.enable && cfg.agent.cron.enable) (
      let
        cronDir   = ./ms-researcher-cron;
        cronFiles = builtins.attrNames (builtins.readDir cronDir);
      in {
        systemd.tmpfiles.rules = [
          "d /home/ms-researcher/.hermes 0700 ms-researcher ms-researcher -"
          "d /home/ms-researcher/.hermes/cron 0755 ms-researcher ms-researcher -"
        ] ++ map
          (n: "L+ /home/ms-researcher/.hermes/cron/${n} - - - - ${cronDir}/${n}")
          cronFiles;
      }
    ))

    (lib.mkIf (cfg.enable && cfg.agent.kb.enable) {
      systemd.tmpfiles.rules = [
        "d ${cfg.agent.kb.path}            0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/journals   0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/pages      0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/raw        0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/queries    0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/reports    0750 ms-researcher ms-researcher -"
        "C  ${cfg.agent.kb.path}/README.md 0640 ms-researcher ms-researcher - ${kbReadmeSrc}"
        "d /home/ms-researcher/kb         0750 ms-researcher ms-researcher -"
      ];

      fileSystems."/home/ms-researcher/kb" = {
        device  = cfg.agent.kb.path;
        fsType  = "none";
        options = [ "bind" ];
      };
    })

    (lib.mkIf cfg.agent.enable {
      systemd.tmpfiles.rules = [
        "d /home/ms-researcher/.hermes 0700 ms-researcher ms-researcher -"
      ] ++ lib.optionals (cfg.agent.soulFile != null) [
        "L+ /home/ms-researcher/.hermes/SOUL.md - - - - ${cfg.agent.soulFile}"
        "h /home/ms-researcher/.hermes/SOUL.md - ms-researcher ms-researcher - -"
      ] ++ lib.optionals (cfg.agent.mcps != [ ]) [
        "L+ /home/ms-researcher/.hermes/mcp.json - - - - ${mcpServersJson}"
        "h /home/ms-researcher/.hermes/mcp.json - ms-researcher ms-researcher - -"
      ];

      systemd.services.ms-researcher-hermes-agent = {
        description = "Hermes Agent (MS Researcher)";
        restartTriggers =
          lib.optional (cfg.agent.soulFile != null) cfg.agent.soulFile
          ++ lib.optional (cfg.agent.mcps != [ ]) mcpServersJson;
        after  = [ "network-online.target" ];
        wants  = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          HOME = "/home/ms-researcher";
          HERMES_GATEWAY_HOST = cfg.agent.gatewayBind;
          HERMES_GATEWAY_PORT = toString cfg.agent.gatewayPort;
          PYTHONUNBUFFERED = "1";
        };
        serviceConfig = {
          User  = "ms-researcher";
          Group = "ms-researcher";
          WorkingDirectory = "/home/ms-researcher";
          ExecStart = "${cfg.agent.package}/bin/hermes gateway";
          Restart = "on-failure";
          RestartSec = 10;
          TimeoutStopSec = "240s";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ReadWritePaths = [ "/home/ms-researcher" cfg.agent.kb.path ];
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
        } // lib.optionalAttrs (cfg.agent.searxngDomainSopsKey != null) {
          ${cfg.agent.searxngDomainSopsKey} = { };
        };

        sops.templates."ms-researcher-matrix-bootstrap-secret.yaml" = {
          content = ''
            apiVersion: v1
            kind: Secret
            metadata:
              name: ms-researcher-matrix-bootstrap
              namespace: matrix
            type: Opaque
            stringData:
              bot_password: "${config.sops.placeholder.${cfg.agent.matrix.passwordSopsKey}}"
              shared_secret: "${config.sops.placeholder.${cfg.agent.matrix.sharedSecretSopsKey}}"
              server_name: "${config.sops.placeholder.${cfg.agent.matrix.serverDomainSopsKey}}"
          '';
          path  = "/var/lib/rancher/k3s/server/manifests/ms-researcher-matrix-bootstrap-secret.yaml";
          owner = "root";
          group = "root";
          mode  = "0600";
        };

        systemd.tmpfiles.rules = [
          "d /home/ms-researcher/.hermes 0700 ms-researcher ms-researcher -"
        ] ++ lib.optionals (cfg.agent.matrix.avatarImage != null) [
          "d /etc/ms-researcher 0755 root root -"
          "C+ /etc/ms-researcher/avatar.png 0444 root root - ${cfg.agent.matrix.avatarImage}"
        ];

        sops.templates."ms-researcher-hermes-env" = {
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
              MATRIX_HOME_ROOM_NAME=MS Research
            ''}
            ${lib.optionalString (cfg.agent.searxngDomainSopsKey != null)
              "SEARXNG_DOMAIN=${config.sops.placeholder.${cfg.agent.searxngDomainSopsKey}}"}
            KB_ROOT=${cfg.agent.kb.path}
          '';
          path  = "/home/ms-researcher/.hermes/.env";
          owner = "ms-researcher";
          group = "ms-researcher";
          mode  = "0600";
          restartUnits = [ "ms-researcher-hermes-agent.service" ];
        };

        services.k3s.manifests.ms-researcher-matrix-bootstrap.content = {
          apiVersion = "batch/v1";
          kind = "Job";
          metadata = {
            name = "ms-researcher-matrix-bootstrap";
            namespace = "matrix";
          };
          spec = {
            backoffLimit = 5;
            template.spec = {
              restartPolicy = "Never";
              volumes = lib.optional (cfg.agent.matrix.avatarImage != null) {
                name = "avatar";
                hostPath = {
                  path = "/etc/ms-researcher/avatar.png";
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

                    if [ -f /etc/ms-researcher-avatar/avatar ]; then
                      MXC=$(curl -fsS -X POST \
                        "$SYNAPSE/_matrix/media/v3/upload?filename=ms-researcher" \
                        -H "Authorization: Bearer $ACCESS_TOKEN" \
                        -H "Content-Type: $AVATAR_MIME" \
                        --data-binary "@/etc/ms-researcher-avatar/avatar" \
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
                    fi
                  ''
                ];
                env = [
                  { name = "BOT_USER";     value = cfg.agent.matrix.userLocalpart; }
                  { name = "DISPLAY_NAME"; value = cfg.agent.matrix.displayName; }
                  { name = "AVATAR_MIME";  value = cfg.agent.matrix.avatarMimeType; }
                  {
                    name = "BOT_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "ms-researcher-matrix-bootstrap";
                      key  = "bot_password";
                    };
                  }
                  {
                    name = "SHARED_SECRET";
                    valueFrom.secretKeyRef = {
                      name = "ms-researcher-matrix-bootstrap";
                      key  = "shared_secret";
                    };
                  }
                  {
                    name = "SERVER_NAME";
                    valueFrom.secretKeyRef = {
                      name = "ms-researcher-matrix-bootstrap";
                      key  = "server_name";
                    };
                  }
                ];
                volumeMounts = lib.optional (cfg.agent.matrix.avatarImage != null) {
                  name = "avatar";
                  mountPath = "/etc/ms-researcher-avatar/avatar";
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
