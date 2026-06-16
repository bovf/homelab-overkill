{
  config,
  pkgs,
  lib,
  ...
}: let
  # ──────────────────────────────────────────────────────────────────────
  # Probe paths: zero-legit-use URLs that scanners hit. Anything matching
  # any of these prefixes is denied at the Traefik layer before reaching
  # Pangolin or its routed backends. Edit this list to add/remove blocks.
  # ──────────────────────────────────────────────────────────────────────
  probePathPrefixes = [
    "/.git/"
    "/.env"
    "/.aws/"
    "/.docker/"
    "/.ssh/"
    "/.htaccess"
    "/.htpasswd"
    "/.DS_Store"
    "/phpMyAdmin"
    "/pma"
    "/myadmin"
    "/wp-login.php"
    "/wp-admin"
    "/wp-content"
    "/wp-includes"
    "/manager/html"
    "/server-status"
  ];

  # ──────────────────────────────────────────────────────────────────────
  # TODO(security): move `adminIPs` into secrets/secrets.yaml (e.g. as
  # an `ADMIN_IPS=83.228.91.14,…` line under pangolin.env) and pull it
  # in here from `config.sops.secrets.…`. Plain-text in-flake leaks
  # personal/home network locations to anyone with read access to this
  # repo or its git history. Acceptable while the repo is private; flip
  # to sops before any open-sourcing or contributor onboarding.
  # ──────────────────────────────────────────────────────────────────────
  adminIPs = [
    "83.228.91.14" # dobry — current home IP
  ];

  fail2banIgnoreCIDRs =
    ["127.0.0.1/8" "::1"] ++ map (ip: "${ip}/32") adminIPs;

  # Traefik rule expression: matches any of probePathPrefixes.
  probeRule =
    lib.concatMapStringsSep " || " (p: "PathPrefix(`${p}`)") probePathPrefixes;

  # Fail2ban regex alternation (escape dots, leave slashes alone).
  escapeRegex = builtins.replaceStrings ["."] ["\\."];
  probeRegexAlt =
    lib.concatMapStringsSep "|" escapeRegex probePathPrefixes;
in {
  # ─── Layer 1: Traefik path-deny ────────────────────────────────────────
  # A router with priority 99999 matches probe paths first; the deny-403
  # middleware (ipAllowList with only loopback) rejects everything from a
  # non-loopback source IP. Returns 403, never reaches the empty backend
  # service.
  #
  # The probePathPrefixes list above is the kill-switch: shrink/widen it
  # in this file to relax or tighten the block. No false positives have
  # been observed in the user's audit log against the current list.
  services.traefik.dynamicConfigOptions.http = {
    middlewares.deny-non-loopback.ipAllowList.sourceRange = ["127.0.0.1/32"];

    routers.block-probes = {
      rule = probeRule;
      priority = 99999;
      service = "block-probes-svc";
      middlewares = ["deny-non-loopback"];
      entryPoints = ["web" "websecure"];
    };

    # Empty load-balancer; the middleware short-circuits with 403 before
    # the request would have reached this anyway. Required because Traefik
    # routers must reference a defined service.
    services.block-probes-svc.loadBalancer.servers = [];
  };

  # ─── Traefik access log (feeds fail2ban) ───────────────────────────────
  # Only 4xx/5xx are written → keeps the log compact (Jellyfin's ~23k 200s
  # per audit window stay out), but every blocked probe is recorded.
  # WorkingDirectory of the traefik unit already has write access to this
  # path, so no extra ReadWritePaths override needed.
  services.traefik.staticConfigOptions.accessLog = {
    filePath = "/var/lib/pangolin/config/traefik/access.log";
    format = "common";
    filters.statusCodes = ["400-599"];
    # bufferingSize=0 → synchronous writes so fail2ban sees probes in the
    # log immediately rather than after a 100-line batch fills up.
    bufferingSize = 0;
  };

  # ─── Layer 2: fail2ban ────────────────────────────────────────────────
  # Bans IPs that hit ≥5 probe paths within a 10-minute window. Repeat
  # offenders escalate via bantime-increment (1h → 4h → 1d → 1wk → 1mo).
  #
  # `ignoreIP` is the safety net: any IP here is NEVER banned, even if it
  # somehow trips the filter. To unban a banned IP manually:
  #
  #     fail2ban-client set traefik-probes unbanip <ip>
  #     fail2ban-client unban <ip>           # global
  #     fail2ban-client unban --all          # nuke everything (paranoia)
  #
  # To make a ban impossible going forward: add the IP to `adminIPs`
  # above (or, once the sops TODO lands, to the secret-managed list).
  services.fail2ban = {
    enable = true;
    ignoreIP = fail2banIgnoreCIDRs;

    bantime-increment = {
      enable = true;
      multipliers = "1 4 24 168 720";
      maxtime = "30d";
    };

    jails.traefik-probes.settings = {
      enabled = true;
      filter = "traefik-probes";
      backend = "polling";
      findtime = 600;
      maxretry = 5;
      bantime = 3600;
      logpath = "/var/lib/pangolin/config/traefik/access.log";
    };
  };

  # Custom fail2ban filter — matches any probe-path request in the
  # Traefik common-log access log, regardless of status code (anyone
  # asking for /.git/config is hostile even on a 404 fallthrough).
  environment.etc."fail2ban/filter.d/traefik-probes.conf".text = ''
    [Definition]
    failregex = ^<HOST> .* "(GET|POST|HEAD|PUT|DELETE|OPTIONS) (${probeRegexAlt})[^"]*"
    ignoreregex =
  '';
}
