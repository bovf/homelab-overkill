{
  config,
  pkgs,
  lib,
  ...
}:
# Element Call / MatrixRTC backend — native NixOS services (no Docker).
#   services.livekit         : the SFU.
#   services.lk-jwt-service  : mints LiveKit JWTs after a Synapse OpenID check.
# Both are fronted by the Pangolin Traefik over HTTPS; call media is direct on
# 7881/tcp + 50000/udp (opened in firewall.nix). Element X and modern Element
# Web call only via Element Call — there is no legacy 1:1 path.
let
  livekitDomain = "livekit.dobryops.com";
  lkJwtDomain = "lk-jwt.dobryops.com";
  homeserverName = "matrix.dobryops.com";
in {
  # LiveKit API key/secret as a `<keyname>: <secret>` keyfile — consumed (via
  # systemd LoadCredential) by BOTH livekit and lk-jwt-service. Rendered from
  # the two sops secrets so neither value lands in the nix store.
  sops.secrets."matrix/livekit-api-key" = {};
  sops.secrets."matrix/livekit-api-secret" = {};
  sops.templates."livekit-keyfile" = {
    content = "${config.sops.placeholder."matrix/livekit-api-key"}: ${config.sops.placeholder."matrix/livekit-api-secret"}";
    restartUnits = ["livekit.service" "lk-jwt-service.service"];
  };

  services.livekit = {
    enable = true;
    keyFile = config.sops.templates."livekit-keyfile".path;
    # 7880 is fronted by Traefik (TLS) and must NOT be public; openFirewall
    # would expose it, so it stays off — firewall.nix opens only 7881 + the
    # UDP media range.
    openFirewall = false;
    settings = {
      port = 7880;
      rtc = {
        tcp_port = 7881;
        # Single-port UDP mux shared by every call. LiveKit gives port_range_*
        # precedence, so zero the NixOS module's default range or the mux never
        # opens and clients get no usable public UDP candidate.
        udp_port = 50000;
        port_range_start = 0;
        port_range_end = 0;
        use_external_ip = false;
        # Advertise only the uplink's address — no docker0 / WireGuard /
        # link-local. Pinning the interface (rather than node_ip) keeps the
        # public IP out of the repo; enp1s0 carries the VPS's public IPv4.
        interfaces.includes = ["enp1s0"];
      };
    };
  };

  services.lk-jwt-service = {
    enable = true;
    keyFile = config.sops.templates."livekit-keyfile".path;
    livekitUrl = "wss://${livekitDomain}";
    port = 8080;
  };

  # The module exposes no option for this — restrict token minting to our own
  # homeserver (the lk-jwt-service default is `*`, i.e. any homeserver).
  systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS =
    homeserverName;

  # ── Traefik routes ───────────────────────────────────────────────────
  # ACME resolver `letsencrypt` (HTTP-01) is the pangolin module's own;
  # guards.nix is the dynamicConfigOptions precedent. Traefik proxies the
  # LiveKit WebSocket transparently over a plain http loadBalancer.
  services.traefik.dynamicConfigOptions.http = {
    routers = {
      livekit = {
        rule = "Host(`${livekitDomain}`)";
        service = "livekit-svc";
        entryPoints = ["websecure"];
        tls.certResolver = "letsencrypt";
      };
      lk-jwt = {
        rule = "Host(`${lkJwtDomain}`)";
        service = "lk-jwt-svc";
        entryPoints = ["websecure"];
        tls.certResolver = "letsencrypt";
      };
    };
    services = {
      livekit-svc.loadBalancer.servers = [{url = "http://127.0.0.1:7880";}];
      lk-jwt-svc.loadBalancer.servers = [{url = "http://127.0.0.1:8080";}];
    };
  };
}
