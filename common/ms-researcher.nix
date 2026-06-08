{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.ms-researcher;
  kbRoot = "/var/lib/ms-researcher/kb";
in {
  options.services.ms-researcher = {
    enable = lib.mkEnableOption "MS researcher — third hermes-agent host integration (citation-grounded knowledgebase)";
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
      model = {
        seedConfig = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Seed /home/ms-researcher/.hermes/config.yaml once with the preferred model/provider. Uses tmpfiles C, so an existing mutable Hermes config is not overwritten.";
        };
        provider = lib.mkOption {
          type = lib.types.str;
          default = "openai-codex";
          description = "Hermes model.provider for ms-researcher. openai-codex uses the ChatGPT/Codex subscription OAuth flow.";
        };
        default = lib.mkOption {
          type = lib.types.str;
          default = "gpt-5.4-mini";
          description = "Default model for the research librarian. Use /model or edit config.yaml for occasional gpt-5.5 deep-review sessions.";
        };
        openaiRuntime = lib.mkOption {
          type = lib.types.enum ["auto" "codex_app_server"];
          default = "auto";
          description = "Hermes model.openai_runtime. Keep auto for Matrix/MCP research; codex_app_server is mainly for coding/file-op sessions.";
        };
      };
      soulFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = ./ms-researcher-soul.md;
        description = "Path to SOUL.md — hermes auto-loads this as the agent's identity. Symlinked into /home/ms-researcher/.hermes/SOUL.md on activation. Null disables deployment.";
      };
      kb = {
        enable = lib.mkEnableOption "knowledgebase tree at /var/lib/ms-researcher/kb (bind-mounted into /home/ms-researcher/kb)";
        path = lib.mkOption {
          type = lib.types.str;
          default = kbRoot;
          description = "Host directory holding the Logseq-browseable kb tree. Bind-mounted into /home/ms-researcher/kb so the agent sees it under HOME.";
        };
        git = {
          enable = lib.mkEnableOption "declarative git/ssh wiring for the ms-researcher knowledgebase repo";
          remote = lib.mkOption {
            type = lib.types.str;
            default = "git@gitlab.dobryops.com:knowledge-base/ms-researcher-kb.git";
            description = "Git remote for the mutable KB working tree. The repo itself is initialized manually as ms-researcher; Nix wires credentials and sync.";
          };
          branch = lib.mkOption {
            type = lib.types.str;
            default = "main";
          };
          sshHost = lib.mkOption {
            type = lib.types.str;
            default = "gitlab.dobryops.com";
          };
          sshPort = lib.mkOption {
            type = lib.types.port;
            default = 2222;
            description = "GitLab SSH service port. Must match the LAN/Pangolin GitLab shell port, not default SSH/22.";
          };
          sshKeySopsKey = lib.mkOption {
            type = lib.types.str;
            default = "hermes/ms_researcher_kb_git_ssh_key";
            description = "sops key containing an OpenSSH private key with write access to the KB repo.";
          };
          sync = {
            enable = lib.mkEnableOption "periodically commit and push KB changes when the KB is already a git repo";
            interval = lib.mkOption {
              type = lib.types.str;
              default = "10min";
              description = "systemd OnUnitActiveSec interval for KB git sync.";
            };
          };
        };
      };
      matrix = {
        enable = lib.mkEnableOption "Matrix adapter — bootstraps @<localpart>:<server> on Synapse";
        serverDomainSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "pangolin/resources/matrix/domain";
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
          description = "Path to the bot's avatar image. Null skips avatar upload (bot will appear with no avatar — Matrix default).";
        };
        avatarMimeType = lib.mkOption {
          type = lib.types.str;
          default = "image/png";
        };
        authorizedUsersSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "hermes/ms_researcher_matrix_allowed_users";
          description = "sops key holding a CSV list of mxids allowed to command the bot. Null omits MATRIX_ALLOWED_USERS.";
        };
        allowedRoomsSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "hermes/ms_researcher_matrix_allowed_rooms";
          description = "sops key holding a CSV list of Matrix room IDs the bot will respond in. Null omits MATRIX_ALLOWED_ROOMS.";
        };
        homeChannelChatIdSopsKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "hermes/ms_researcher_matrix_home_channel";
          description = "sops key holding a single Matrix room ID rendered as MATRIX_HOME_ROOM in the agent's .env. Used by the weekly digest cron to deliver into the shared room.";
        };
        passwordSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "hermes/ms_researcher_matrix_password";
          description = "sops key holding the bot user's matrix password.";
        };
        sharedSecretSopsKey = lib.mkOption {
          type = lib.types.str;
          default = "matrix/synapse/registration_shared_secret";
          description = "sops key holding synapse's registration_shared_secret (shared with hale / koth-dm).";
        };
        synapseImage = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/element-hq/synapse:v1.153.0";
          description = "Synapse image used by the bootstrap Job.";
        };
      };
      searxngDomainSopsKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "pangolin/resources/search/domain";
        description = "sops key holding the SearXNG host. Rendered as SEARXNG_DOMAIN in the agent's .env so the searxng MCP can target it. Null disables the wiring.";
      };
      skills.enable = lib.mkEnableOption "publish bundled skills from common/ms-researcher-skills/ into /home/ms-researcher/.hermes/skills/";
      skills.dropBundled = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run `hermes skills opt-out --remove --yes` as ms-researcher on every service start. Writes a `.no-bundled-skills` marker so hermes stops seeding its built-in skill tree (devops/, software-development/, kanban-*, etc.) into ms-researcher's profile. Curated skills come exclusively from common/ms-researcher-skills/. Strongly recommended for the research persona — unrelated bundled skills muddy the cite-or-silent loop.";
      };
      cron.enable = lib.mkEnableOption "publish bundled cron jobs from common/ms-researcher-cron/ into /home/ms-researcher/.hermes/cron/";
      mcps.enable = lib.mkEnableOption "register the ms-researcher MCP servers (pubmed, searxng, crossref) with hermes via ExecStartPre. Built from common/mcps/{pubmed,searxng,crossref}/ as Python packages using the official mcp SDK's FastMCP.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      users.groups.ms-researcher = {};
      users.users.ms-researcher = {
        isSystemUser = true;
        group = "ms-researcher";
        description = "MS Researcher (hermes-agent)";
        home = "/home/ms-researcher";
        createHome = true;
        shell = pkgs.bashInteractive;
        extraGroups = ["systemd-journal"];
        openssh.authorizedKeys.keys =
          config.users.users.engineer.openssh.authorizedKeys.keys;
      };

      environment.systemPackages = [cfg.agent.package];
    }

    (lib.mkIf (cfg.enable && cfg.agent.skills.enable) (
      let
        skillsDir = ./ms-researcher-skills;
        skillNames = builtins.attrNames (builtins.readDir skillsDir);
      in {
        systemd.tmpfiles.rules =
          [
            "d /home/ms-researcher/.hermes 0700 ms-researcher ms-researcher -"
            "d /home/ms-researcher/.hermes/skills 0755 ms-researcher ms-researcher -"
          ]
          ++ map
          (n: "L+ /home/ms-researcher/.hermes/skills/${n} - - - - ${skillsDir}/${n}")
          skillNames;
      }
    ))

    (lib.mkIf (cfg.enable && cfg.agent.cron.enable) (
      let
        cronDir = ./ms-researcher-cron;
        cronFiles = builtins.attrNames (builtins.readDir cronDir);
      in {
        systemd.tmpfiles.rules =
          [
            "d /home/ms-researcher/.hermes 0700 ms-researcher ms-researcher -"
            "d /home/ms-researcher/.hermes/cron 0755 ms-researcher ms-researcher -"
          ]
          ++ map
          (n: "L+ /home/ms-researcher/.hermes/cron/${n} - - - - ${cronDir}/${n}")
          cronFiles;
      }
    ))

    (lib.mkIf (cfg.enable && cfg.agent.kb.enable) {
      systemd.tmpfiles.rules = [
        "d ${cfg.agent.kb.path}            0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/journals   0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/pages      0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/pages/indexes 0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/content    0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/content/studies 0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/content/trials 0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/content/practical 0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/content/reports 0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/content/queries 0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/raw        0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/raw/rss    0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/raw/manual 0750 ms-researcher ms-researcher -"
        # Legacy flat dirs stay present during migration; kb-maintain moves content into V2.
        "d ${cfg.agent.kb.path}/queries    0750 ms-researcher ms-researcher -"
        "d ${cfg.agent.kb.path}/reports    0750 ms-researcher ms-researcher -"
        "d /home/ms-researcher/kb         0750 ms-researcher ms-researcher -"
      ];

      fileSystems."/home/ms-researcher/kb" = {
        device = cfg.agent.kb.path;
        fsType = "none";
        options = ["bind"];
      };
    })

    (lib.mkIf (cfg.enable && cfg.agent.kb.enable && cfg.agent.kb.git.enable) {
      sops.secrets.${cfg.agent.kb.git.sshKeySopsKey} = {
        owner = "ms-researcher";
        group = "ms-researcher";
        mode = "0400";
      };

      home-manager.users.ms-researcher = {...}: {
        home.username = "ms-researcher";
        home.homeDirectory = "/home/ms-researcher";
        home.stateVersion = "25.05";

        programs.git = {
          enable = true;
          settings = {
            user = {
              name = "MS Research Librarian";
              email = "ms-researcher@matrix.dobryops.com";
            };
            init.defaultBranch = cfg.agent.kb.git.branch;
            pull.rebase = true;
          };
        };

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings.${cfg.agent.kb.git.sshHost} = {
            HostName = cfg.agent.kb.git.sshHost;
            User = "git";
            Port = cfg.agent.kb.git.sshPort;
            IdentityFile = config.sops.secrets.${cfg.agent.kb.git.sshKeySopsKey}.path;
            IdentitiesOnly = true;
            StrictHostKeyChecking = "accept-new";
          };
        };
      };

      systemd.services.ms-researcher-kb-git-sync = lib.mkIf cfg.agent.kb.git.sync.enable {
        description = "Commit and push ms-researcher KB changes";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        path = [pkgs.git pkgs.openssh pkgs.coreutils];
        serviceConfig = {
          Type = "oneshot";
          User = "ms-researcher";
          Group = "ms-researcher";
          WorkingDirectory = cfg.agent.kb.path;
        };
        script = ''
          set -eu

          if [ ! -d .git ]; then
            echo "${cfg.agent.kb.path} is not a git repo yet; initialize it manually as ms-researcher."
            exit 0
          fi

          if ! git remote get-url origin >/dev/null 2>&1; then
            echo "No origin remote configured; expected ${cfg.agent.kb.git.remote}."
            exit 0
          fi

          git add README.md journals pages content raw queries reports 2>/dev/null || true
          git diff --cached --quiet && exit 0

          git commit -m "kb: update research notes"
          git pull --rebase --autostash origin ${cfg.agent.kb.git.branch}
          git push origin HEAD:${cfg.agent.kb.git.branch}
        '';
      };

      systemd.timers.ms-researcher-kb-git-sync = lib.mkIf cfg.agent.kb.git.sync.enable {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = cfg.agent.kb.git.sync.interval;
          Persistent = true;
        };
      };
    })

    (lib.mkIf cfg.agent.enable (
      let
        pubmedMcp = pkgs.callPackage ./mcps/pubmed {};
        searxngMcp = pkgs.callPackage ./mcps/searxng {};
        crossrefMcp = pkgs.callPackage ./mcps/crossref {};
        hermesConfigSeed = pkgs.writeText "ms-researcher-hermes-config.yaml" ''
          model:
            provider: ${cfg.agent.model.provider}
            default: ${cfg.agent.model.default}
            openai_runtime: ${cfg.agent.model.openaiRuntime}
        '';
        mcpSyncScript = pkgs.writeShellScript "ms-researcher-mcp-sync" ''
          set -eu
          HERMES=${cfg.agent.package}/bin/hermes
          # `hermes mcp add` is interactive: after a successful connect it
          # prompts `Enable all N tools? [Y/n/select]:`. Headless EOF
          # cancels — so we pipe `Y` to auto-enable every discovered tool.
          # SEARXNG_DOMAIN comes in via EnvironmentFile (~/.hermes/.env).
          "$HERMES" mcp remove pubmed   >/dev/null 2>&1 || true
          "$HERMES" mcp remove searxng  >/dev/null 2>&1 || true
          "$HERMES" mcp remove crossref >/dev/null 2>&1 || true
          printf 'Y\n' | "$HERMES" mcp add pubmed \
            --command ${pubmedMcp}/bin/ms-mcp-pubmed
          printf 'Y\n' | "$HERMES" mcp add searxng \
            --command ${searxngMcp}/bin/ms-mcp-searxng \
            --env SEARXNG_DOMAIN="''${SEARXNG_DOMAIN:-}"
          printf 'Y\n' | "$HERMES" mcp add crossref \
            --command ${crossrefMcp}/bin/ms-mcp-crossref
        '';
      in {
        systemd.tmpfiles.rules =
          [
            "d /home/ms-researcher/.hermes 0700 ms-researcher ms-researcher -"
          ]
          ++ lib.optionals cfg.agent.model.seedConfig [
            "C /home/ms-researcher/.hermes/config.yaml 0600 ms-researcher ms-researcher - ${hermesConfigSeed}"
          ]
          ++ lib.optionals (cfg.agent.soulFile != null) [
            "L+ /home/ms-researcher/.hermes/SOUL.md - - - - ${cfg.agent.soulFile}"
            "h /home/ms-researcher/.hermes/SOUL.md - ms-researcher ms-researcher - -"
          ];

        systemd.services."hermes-agent.ms-researcher" = {
          description = "Hermes Agent (MS Research Librarian)";
          restartTriggers =
            lib.optional (cfg.agent.soulFile != null) cfg.agent.soulFile
            ++ lib.optional cfg.agent.skills.enable ./ms-researcher-skills
            ++ lib.optional cfg.agent.cron.enable ./ms-researcher-cron;
          after = ["network-online.target"];
          wants = ["network-online.target"];
          wantedBy = ["multi-user.target"];
          environment = {
            HOME = "/home/ms-researcher";
            HERMES_HOME = "/home/ms-researcher/.hermes";
            HERMES_GATEWAY_HOST = cfg.agent.gatewayBind;
            HERMES_GATEWAY_PORT = toString cfg.agent.gatewayPort;
            PYTHONUNBUFFERED = "1";
          };
          serviceConfig = {
            User = "ms-researcher";
            Group = "ms-researcher";
            WorkingDirectory = "/home/ms-researcher";
            EnvironmentFile =
              lib.mkIf cfg.agent.matrix.enable
              "/home/ms-researcher/.hermes/.env";
            ExecStartPre =
              lib.optional cfg.agent.skills.dropBundled
              "${cfg.agent.package}/bin/hermes skills opt-out --remove --yes"
              ++ lib.optional cfg.agent.mcps.enable "${mcpSyncScript}";
            ExecStart = "${cfg.agent.package}/bin/hermes gateway";
            Restart = "on-failure";
            RestartSec = 10;
            TimeoutStopSec = "240s";

            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = "read-only";
            ReadWritePaths =
              ["/home/ms-researcher"]
              ++ lib.optional cfg.agent.kb.enable cfg.agent.kb.path;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
            RestrictNamespaces = true;
            LockPersonality = true;
            CapabilityBoundingSet = "";
            AmbientCapabilities = "";
          };
        };
      }
    ))

    (
      lib.mkIf (cfg.enable && cfg.agent.matrix.enable) {
        nixpkgs.config.permittedInsecurePackages = ["olm-3.2.16"];

        sops.secrets =
          {
            ${cfg.agent.matrix.passwordSopsKey} = {};
            ${cfg.agent.matrix.sharedSecretSopsKey} = {};
            ${cfg.agent.matrix.serverDomainSopsKey} = {};
          }
          // lib.optionalAttrs (cfg.agent.matrix.authorizedUsersSopsKey != null) {
            ${cfg.agent.matrix.authorizedUsersSopsKey} = {};
          }
          // lib.optionalAttrs (cfg.agent.matrix.allowedRoomsSopsKey != null) {
            ${cfg.agent.matrix.allowedRoomsSopsKey} = {};
          }
          // lib.optionalAttrs (cfg.agent.matrix.homeChannelChatIdSopsKey != null) {
            ${cfg.agent.matrix.homeChannelChatIdSopsKey} = {};
          }
          // lib.optionalAttrs (cfg.agent.searxngDomainSopsKey != null) {
            ${cfg.agent.searxngDomainSopsKey} = {};
          };

        sops.templates."hermes-matrix-bootstrap-ms-researcher-secret.yaml" = {
          content = ''
            apiVersion: v1
            kind: Secret
            metadata:
              name: hermes-matrix-bootstrap-ms-researcher
              namespace: matrix
            type: Opaque
            stringData:
              bot_password: "${config.sops.placeholder.${cfg.agent.matrix.passwordSopsKey}}"
              shared_secret: "${config.sops.placeholder.${cfg.agent.matrix.sharedSecretSopsKey}}"
              server_name: "${config.sops.placeholder.${cfg.agent.matrix.serverDomainSopsKey}}"
              ${lib.optionalString (cfg.agent.matrix.homeChannelChatIdSopsKey != null)
              ''home_room: "${config.sops.placeholder.${cfg.agent.matrix.homeChannelChatIdSopsKey}}"''}
          '';
          path = "/var/lib/rancher/k3s/server/manifests/hermes-matrix-bootstrap-ms-researcher-secret.yaml";
          owner = "root";
          group = "root";
          mode = "0600";
        };

        systemd.tmpfiles.rules =
          [
            "d /home/ms-researcher/.hermes 0700 ms-researcher ms-researcher -"
          ]
          ++ lib.optionals (cfg.agent.matrix.avatarImage != null) [
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
          path = "/home/ms-researcher/.hermes/.env";
          owner = "ms-researcher";
          group = "ms-researcher";
          mode = "0600";
          restartUnits = ["hermes-agent.ms-researcher.service"];
        };

        services.k3s.manifests.hermes-matrix-bootstrap-ms-researcher.content = {
          apiVersion = "batch/v1";
          kind = "Job";
          metadata = {
            name = "hermes-matrix-bootstrap-ms-researcher";
            namespace = "matrix";
          };
          spec = {
            backoffLimit = 2;
            ttlSecondsAfterFinished = 3600;
            template.spec = {
              restartPolicy = "Never";
              volumes = lib.optional (cfg.agent.matrix.avatarImage != null) {
                name = "avatar";
                hostPath = {
                  path = "/etc/ms-researcher/avatar.png";
                  type = "File";
                };
              };
              containers = [
                {
                  name = "register";
                  image = cfg.agent.matrix.synapseImage;
                  command = ["bash"];
                  args = [
                    "-ec"
                    ''
                      set -o pipefail
                      SYNAPSE=http://synapse.matrix.svc.cluster.local:8008
                      MXID="@$BOT_USER:$SERVER_NAME"

                      until curl -fsS "$SYNAPSE/_matrix/client/versions" >/dev/null 2>&1; do
                        echo "waiting for synapse..."
                        sleep 3
                      done

                      if curl -fsS "$SYNAPSE/_matrix/client/v3/profile/$MXID" >/dev/null 2>&1; then
                        echo "$MXID already exists; skipping registration"
                      else
                        OUT=$(register_new_matrix_user \
                          -u "$BOT_USER" -p "$BOT_PASSWORD" --no-admin \
                          -k "$SHARED_SECRET" \
                          "$SYNAPSE" 2>&1) || true
                        echo "$OUT"
                        echo "$OUT" | grep -qE 'Success|User ID already taken|already exists' \
                          || { echo "register failed unexpectedly" >&2; exit 1; }
                      fi

                      ACCESS_TOKEN=$(SYNAPSE="$SYNAPSE" python3 - <<'PY'
                      import json
                      import os
                      import sys
                      import time
                      import urllib.error
                      import urllib.request

                      url = os.environ["SYNAPSE"] + "/_matrix/client/v3/login"
                      payload = json.dumps({
                          "type": "m.login.password",
                          "identifier": {"type": "m.id.user", "user": os.environ["BOT_USER"]},
                          "password": os.environ["BOT_PASSWORD"],
                      }).encode()

                      for attempt in range(1, 13):
                          req = urllib.request.Request(
                              url,
                              data=payload,
                              headers={"Content-Type": "application/json"},
                              method="POST",
                          )
                          try:
                              with urllib.request.urlopen(req, timeout=20) as resp:
                                  print(json.load(resp)["access_token"])
                                  raise SystemExit(0)
                          except urllib.error.HTTPError as exc:
                              body = exc.read().decode("utf-8", "replace")
                              if exc.code == 429:
                                  retry_ms = None
                                  try:
                                      retry_ms = json.loads(body).get("retry_after_ms")
                                  except json.JSONDecodeError:
                                      pass
                                  delay = max(1.0, (retry_ms or 5000) / 1000.0)
                                  print(
                                      f"login rate-limited on attempt {attempt}; sleeping {delay:.1f}s",
                                      file=sys.stderr,
                                  )
                                  time.sleep(delay)
                                  continue
                              print(f"login failed with HTTP {exc.code}: {body}", file=sys.stderr)
                              raise SystemExit(1)
                          except Exception as exc:
                              print(f"login failed: {exc}", file=sys.stderr)
                              raise SystemExit(1)

                      print("login failed: still rate-limited after retries", file=sys.stderr)
                      raise SystemExit(1)
                      PY
                      )

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
                      ''}

                      ${lib.optionalString (cfg.agent.matrix.homeChannelChatIdSopsKey != null) ''
                        if [ -n "''${HOME_ROOM:-}" ]; then
                          ROOM_ENC=$(python3 -c 'import os, urllib.parse; print(urllib.parse.quote(os.environ["HOME_ROOM"], safe=""))')
                          curl -fsS -X POST \
                            "$SYNAPSE/_matrix/client/v3/join/$ROOM_ENC" \
                            -H "Authorization: Bearer $ACCESS_TOKEN" \
                            -H 'Content-Type: application/json' \
                            -d '{}'
                          echo "joined $HOME_ROOM as @$BOT_USER:$SERVER_NAME"
                        fi
                      ''}
                    ''
                  ];
                  env =
                    [
                      {
                        name = "BOT_USER";
                        value = cfg.agent.matrix.userLocalpart;
                      }
                      {
                        name = "DISPLAY_NAME";
                        value = cfg.agent.matrix.displayName;
                      }
                      {
                        name = "AVATAR_MIME";
                        value = cfg.agent.matrix.avatarMimeType;
                      }
                      {
                        name = "BOT_PASSWORD";
                        valueFrom.secretKeyRef = {
                          name = "hermes-matrix-bootstrap-ms-researcher";
                          key = "bot_password";
                        };
                      }
                      {
                        name = "SHARED_SECRET";
                        valueFrom.secretKeyRef = {
                          name = "hermes-matrix-bootstrap-ms-researcher";
                          key = "shared_secret";
                        };
                      }
                      {
                        name = "SERVER_NAME";
                        valueFrom.secretKeyRef = {
                          name = "hermes-matrix-bootstrap-ms-researcher";
                          key = "server_name";
                        };
                      }
                    ]
                    ++ lib.optional (cfg.agent.matrix.homeChannelChatIdSopsKey != null) {
                      name = "HOME_ROOM";
                      valueFrom.secretKeyRef = {
                        name = "hermes-matrix-bootstrap-ms-researcher";
                        key = "home_room";
                      };
                    };
                  volumeMounts = lib.optional (cfg.agent.matrix.avatarImage != null) {
                    name = "avatar";
                    mountPath = "/etc/ms-researcher-avatar/avatar";
                    readOnly = true;
                  };
                  resources = {
                    requests = {
                      cpu = "50m";
                      memory = "128Mi";
                    };
                    limits = {
                      cpu = "500m";
                      memory = "256Mi";
                    };
                  };
                }
              ];
            };
          };
        };
      }
    )
  ]);
}
