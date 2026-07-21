{
  config,
  pkgs,
  lib,
  ...
}: let
  baseDomain = "dobryops.com";
  letsEncryptEmail = "dobry@dobryops.com";
  badger = pkgs.fetchFromGitHub {
    owner = "fosrl";
    repo = "badger";
    rev = "v1.2.0";
    hash = "sha256-iHL2amAuiiufb9hlokRP14wHq2Ei2eQdUlYP4FmpS9o=";
  };
in {
  # ─── sops-nix ─────────────────────────────────────────────────────────
  # Decrypts ../../secrets/secrets.yaml using the VPS SSH identity.
  # Existing converted age recipients are supported through age.sshKeyPaths;
  # raw SSH public-key recipients, including RSA workstation recipients, are
  # supported through SOPS_AGE_SSH_PRIVATE_KEY_FILE. At least one matching key
  # must exist before activation.
  #
  #   ssh-keygen -t ed25519 -f /root/.ssh/theadministrator -N ''
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    # Raw SSH public-key SOPS recipients, including RSA workstation keys,
    # require SOPS_AGE_SSH_PRIVATE_KEY_FILE. The current VPS install uses the
    # named host key; bootstrap can still stage /root/.ssh/id_ed25519 for new
    # installs, but do not list missing fallback paths here because sops-nix
    # logs missing SSH keys as activation errors.
    environment.SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/root/.ssh/theadministrator";
    age.sshKeyPaths = ["/root/.ssh/theadministrator"];

    secrets."pangolin/env" = {
      # The pangolin module reads SERVER_SECRET (and any DNS-01 provider creds)
      # from this file. Restart all three units when the secret rotates.
      restartUnits = ["pangolin.service" "gerbil.service" "traefik.service"];
    };
  };

  # ─── Pangolin stack (pangolin + gerbil + traefik) ─────────────────────
  # The module wires Traefik with the four upstream routers, the badger v1.2.0
  # plugin, and the systemd ordering pangolin → gerbil → traefik. Data lives
  # at /var/lib/pangolin (default), same layout as the docker-compose ./config.
  services.pangolin = {
    enable = true;
    inherit baseDomain letsEncryptEmail;
    # dashboardDomain defaults to "pangolin.${baseDomain}" — override here
    # only if the dashboard lives somewhere else.

    environmentFile = config.sops.secrets."pangolin/env".path;

    # Opens 80/tcp, 443/tcp, 51820/udp. 21820/udp (Olm) is NOT auto-opened —
    # we keep it in firewall.nix.
    openFirewall = true;

    # ── ACME ──
    # HTTP-01 (compose default): leave dnsProvider unset.
    # DNS-01 (wildcard certs): set dnsProvider, and put the Traefik provider
    # env vars (e.g. CF_DNS_API_TOKEN=…) in secrets/secrets.yaml under
    # pangolin.env. Example for Cloudflare:
    #
    #   dnsProvider = "cloudflare";
    #
    # Other providers: see https://go-acme.github.io/lego/dns/

    # Free-form passthrough into Pangolin's config.yml. Carried over from the
    # docker-compose deployment's config.yml — only the bits the module's
    # named options above don't already cover.
    settings = {
      server.cors = {
        origins = ["https://pangolin.${baseDomain}"];
        methods = ["GET" "POST" "PUT" "DELETE" "PATCH"];
        allowed_headers = ["X-CSRF-Token" "Content-Type"];
        credentials = false;
      };
      server.maxmind_db_path = "./config/GeoLite2-Country.mmdb";
      flags = {
        require_email_verification = false;
        disable_signup_without_invite = true;
        disable_user_create_org = false;
        allow_raw_resources = true;
        enable_integration_api = true;
      };
    };
  };

  # The pangolin module already configures gerbil via services.gerbil; only
  # set this if gerbil itself needs extra env (rare — most users don't).
  # services.gerbil.environmentFile = config.sops.secrets."pangolin/env".path;

  # ─── Extra Traefik entry points ───────────────────────────────────────
  # The pangolin module sets up `web` (:80) and `websecure` (:443) only.
  # The pre-migration docker-compose Traefik also exposed raw TCP/UDP for
  # Mumble (64738) and a tunneled SSH (2222). Pangolin's HTTP provider
  # populates the routers/services dynamically; here we just open the
  # static entry points so Traefik will accept connections on those ports.
  services.traefik.staticConfigOptions.entryPoints = {
    tcp-2222.address = ":2222/tcp"; # GitLab SSH (HostSNI=*)
    tcp-2223.address = ":2223/tcp"; # Engineer SSH (HostSNI=*)
    tcp-6544.address = ":6544/tcp"; # Engineer k8s API (HostSNI=*)
    tcp-64738.address = ":64738/tcp"; # Mumble TCP
    udp-64738.address = ":64738/udp"; # Mumble UDP
  };

  # Backends (the in-cluster traefik on the Newt-WG IP) serve self-signed
  # certs without IP SANs — without this, every tunneled HTTPS route
  # returns 500 with "cannot validate certificate ... doesn't contain any
  # IP SANs". The docker-compose traefik_config.yml had the equivalent.
  services.traefik.staticConfigOptions.serversTransport.insecureSkipVerify = true;

  # Traefik 3.5.3+ disables every plugin-backed router when its registry is
  # briefly unreachable at startup (traefik/traefik#13005). Load Pangolin's
  # pinned Badger source locally instead, so a rebuild cannot turn every
  # external resource into Traefik's default 404.
  services.traefik.staticConfigOptions.experimental = lib.mkForce {
    localPlugins.badger.moduleName = "github.com/fosrl/badger";
  };
  systemd.services.traefik.preStart = ''
    install -d plugins-local/src/github.com/fosrl
    ln -sfn ${badger} plugins-local/src/github.com/fosrl/badger
  '';

  # The pangolin module declares Traefik as PartOf=gerbil.service, which
  # races with `switch-to-configuration`'s stop→activate→start dance on
  # every redeploy: PartOf re-spawns Traefik between the stop and start
  # phases using systemd's pre-daemon-reload cached unit, so the new
  # ExecStart's --configfile path is silently ignored. The user-visible
  # symptom is "deploy succeeded but Traefik is still on the old config"
  # and requiring a manual `systemctl restart traefik` after every
  # rebuild that touches a Traefik option.
  #
  # `stopIfChanged = false` makes NixOS issue a single atomic
  # `systemctl restart traefik` instead — which respects the daemon-
  # reload and starts the new process with the correct ExecStart.
  systemd.services.traefik.stopIfChanged = false;

  # ─── Workaround: re-register basic-WG peers with gerbil on restart ────
  # When gerbil restarts, pangolin's /api/v1/gerbil/get-config returns
  # {"mappings":{}} for basic-WG sites (the handler walks active Newt
  # websocket sessions, which basic-WG peers don't have). Gerbil then
  # drops their AllowedIPs from its wgctrl state and the kernel returns
  # EKEYREJECTED ("Required key not available") for any packet destined
  # to those peers — traefik → 100.89.128.x fails with 502 Bad Gateway.
  #
  # This oneshot reads basic-WG site rows (type='wireguard') straight
  # from pangolin's SQLite and POSTs each {publicKey, allowedIps} back to
  # gerbil's /peer endpoint (same call the dashboard makes on site
  # creation). Wantedby gerbil.service so it re-runs on every gerbil
  # start, including restarts triggered by the upstream
  # `close of closed channel` panic in gerbil/relay/relay.go:264.
  #
  # Remove once upstream pangolin includes basic-WG sites in
  # /api/v1/gerbil/get-config.
  systemd.services.gerbil-basic-wg-reconcile = {
    description = "Re-register basic-WG site peers with gerbil";
    after = ["gerbil.service"];
    wantedBy = ["gerbil.service"];
    path = [pkgs.sqlite pkgs.curl pkgs.coreutils];
    serviceConfig = {
      Type = "oneshot";
      # Pangolin's DB is owned pangolin:fossorial; root bypasses mode bits.
      User = "root";
    };
    script = ''
      set -euo pipefail
      DB=/var/lib/pangolin/config/db/db.sqlite
      GERBIL=http://localhost:3004

      # Wait up to 30s for gerbil's HTTP control plane to accept requests.
      for i in $(seq 1 30); do
        if curl -fsS -o /dev/null "$GERBIL/metrics" 2>/dev/null; then break; fi
        sleep 1
      done

      sqlite3 -separator '|' "$DB" \
        "SELECT pubKey, subnet FROM sites \
         WHERE type = 'wireguard' AND pubKey IS NOT NULL AND subnet IS NOT NULL;" \
      | while IFS='|' read -r pubkey subnet; do
          [ -z "$pubkey" ] && continue
          echo "reconciling basic-WG peer: pubkey=$pubkey allowedIps=$subnet"
          curl -fsS -X POST "$GERBIL/peer" \
            -H 'Content-Type: application/json' \
            -d "{\"publicKey\":\"$pubkey\",\"allowedIps\":[\"$subnet\"]}" \
            || echo "  POST failed for $pubkey; continuing" >&2
        done
    '';
  };
}
