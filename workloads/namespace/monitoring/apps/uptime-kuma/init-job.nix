# Declarative bootstrap of Uptime Kuma: create the initial admin user
# (first run only), then sync monitors + the "homelab" public status
# page that Glance reads via /api/status-page/heartbeat/homelab.
#
# Kuma's API is Socket.IO, not REST. The community-maintained Python
# library uptime-kuma-api wraps it. We pip-install it at Job runtime
# in a python:3.11-slim container — same pattern as stalwart's
# alpine+curl bootstrap, just python+pip instead.
#
# Idempotent: existing monitors are matched by name, only missing ones
# get created. Existing status page is updated in place.
{ config, ... }:

let
  adminUser = config.sops.placeholder."uptime-kuma/admin_user";
  adminPwd  = config.sops.placeholder."uptime-kuma/admin_password";

  # Service domains — each is a sops placeholder so this whole file is
  # safe in plaintext .nix. Add/remove monitors here, the init-job
  # picks them up on next deploy.
  monitor = name: domain: { inherit name; url = "https://${domain}"; };

  monitors = [
    # Media
    (monitor "Jellyfin"      config.sops.placeholder."pangolin/resources/jellyfin/domain")
    (monitor "Jellyseerr"    config.sops.placeholder."pangolin/resources/jellyseerr/domain")
    (monitor "Sonarr"        config.sops.placeholder."pangolin/resources/sonarr/domain")
    (monitor "Radarr"        config.sops.placeholder."pangolin/resources/radarr/domain")
    (monitor "Sportarr"      config.sops.placeholder."pangolin/resources/sportarr/domain")
    (monitor "Bazarr"        config.sops.placeholder."pangolin/resources/bazarr/domain")
    (monitor "Prowlarr"      config.sops.placeholder."pangolin/resources/prowlarr/domain")
    (monitor "qBittorrent"   config.sops.placeholder."pangolin/resources/qbittorrent/domain")
    (monitor "NZBGet"        config.sops.placeholder."pangolin/resources/nzbget/domain")
    # Dev / CI
    (monitor "GitLab"        config.sops.placeholder."pangolin/resources/gitlab/domain")
    (monitor "ArgoCD"        config.sops.placeholder."pangolin/resources/argocd/domain")
    # Ops
    (monitor "Grafana"       config.sops.placeholder."pangolin/resources/grafana/domain")
    (monitor "Prometheus"    config.sops.placeholder."pangolin/resources/prometheus/domain")
    (monitor "Alertmanager"  config.sops.placeholder."pangolin/resources/alertmanager/domain")
    (monitor "Pi-hole"       config.sops.placeholder."pangolin/resources/pihole/domain")
    (monitor "MinIO"         config.sops.placeholder."pangolin/resources/minio_console/domain")
    (monitor "pgAdmin"       config.sops.placeholder."pangolin/resources/pgadmin/domain")
    # Comms
    (monitor "Matrix"        config.sops.placeholder."pangolin/resources/element/domain")
    (monitor "Synapse Admin" config.sops.placeholder."pangolin/resources/synapse_admin/domain")
    (monitor "Mail"          config.sops.placeholder."pangolin/resources/mailadmin/domain")
    # Personal
    (monitor "ezBookkeeping" config.sops.placeholder."pangolin/resources/ezbookkeeping/domain")
    (monitor "Blog"          config.sops.placeholder."pangolin/resources/whoami/domain")
    # Self / Dashboard
    (monitor "SearXNG"       config.sops.placeholder."pangolin/resources/search/domain")
    (monitor "Speedtest"     config.sops.placeholder."pangolin/resources/speedtest/domain")
  ];

  monitorsJson = builtins.toJSON monitors;
in
{
  # Bootstrap creds for the Job. Separate Secret from any user-managed
  # secrets so the Job only mounts what it needs.
  sops.templates."uptime-kuma/bootstrap-secret.yaml" = {
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: uptime-kuma-bootstrap-creds
        namespace: monitoring
      type: Opaque
      stringData:
        admin_user: "${adminUser}"
        admin_password: "${adminPwd}"
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/uptime-kuma-bootstrap-secret.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  # Monitor list rendered via sops so domain placeholders resolve. The
  # bootstrap Job mounts this as /config/monitors.json.
  sops.templates."uptime-kuma/monitors.yaml" = {
    content = ''
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: uptime-kuma-monitors
        namespace: monitoring
      data:
        monitors.json: |
          ${monitorsJson}
    '';
    path  = "/var/lib/rancher/k3s/server/manifests/uptime-kuma-monitors.yaml";
    owner = "root";
    group = "root";
    mode  = "0644";
  };

  services.k3s.manifests.uptime-kuma-bootstrap-job.content = {
    apiVersion = "batch/v1";
    kind       = "Job";
    metadata = {
      name      = "uptime-kuma-bootstrap";
      namespace = "monitoring";
      annotations = {
        # Bump on script changes to force re-run (delete old Job + apply new).
        "homelab.dobryops.com/bootstrap-version" = "2";
      };
    };
    spec = {
      backoffLimit            = 5;
      ttlSecondsAfterFinished = 86400;
      template.spec = {
        restartPolicy = "OnFailure";
        volumes = [
          {
            name = "monitors";
            configMap.name = "uptime-kuma-monitors";
          }
        ];
        containers = [{
          name    = "bootstrap";
          image   = "python:3.11-slim";
          envFrom = [{ secretRef.name = "uptime-kuma-bootstrap-creds"; }];
          env = [
            { name = "KUMA_URL"; value = "http://uptime-kuma.monitoring.svc.cluster.local:3001"; }
          ];
          volumeMounts = [{
            name      = "monitors";
            mountPath = "/config";
            readOnly  = true;
          }];
          command = [ "sh" "-ec" ];
          args = [
            ''
              pip install --quiet --root-user-action=ignore "uptime-kuma-api==1.2.1"
              python - <<'PY'
              import json, os, time
              from uptime_kuma_api import UptimeKumaApi, MonitorType

              URL  = os.environ["KUMA_URL"]
              USER = os.environ["admin_user"]
              PASS = os.environ["admin_password"]

              print(f"Connecting to {URL} ...", flush=True)
              api = None
              for attempt in range(60):
                  try:
                      api = UptimeKumaApi(URL)
                      break
                  except Exception as e:
                      print(f"  retry {attempt}: {e}", flush=True)
                      time.sleep(2)
              if api is None:
                  raise SystemExit("Kuma unreachable after 2min")

              if api.need_setup():
                  print("First-run setup — creating admin", flush=True)
                  api.setup(USER, PASS)

              api.login(USER, PASS)
              print("Authenticated.", flush=True)

              with open("/config/monitors.json") as f:
                  declared = json.load(f)

              existing = {m["name"]: m for m in api.get_monitors()}
              ids = []
              for mon in declared:
                  if mon["name"] in existing:
                      ids.append(existing[mon["name"]]["id"])
                      print(f"  = {mon['name']} (exists, id={existing[mon['name']]['id']})", flush=True)
                      continue
                  res = api.add_monitor(
                      type=MonitorType.HTTP,
                      name=mon["name"],
                      url=mon["url"],
                      interval=60,
                      retryInterval=20,
                      maxretries=3,
                      accepted_statuscodes=["200-299", "301", "302"],
                  )
                  ids.append(res["monitorID"])
                  print(f"  + {mon['name']} (created, id={res['monitorID']})", flush=True)

              status_groups = [{
                  "name": "Services",
                  "weight": 1,
                  "monitorList": [{"id": i, "sendUrl": 0} for i in ids],
              }]

              try:
                  api.get_status_page("homelab")
                  print("Status page 'homelab' exists — updating", flush=True)
              except Exception:
                  print("Creating status page 'homelab'", flush=True)
                  api.add_status_page("Homelab", "homelab")

              api.save_status_page(
                  slug="homelab",
                  title="Homelab",
                  description="Service health for the dashboard SERVICES grid",
                  publicGroupList=status_groups,
                  showTags=False,
              )
              print("Status page synced.", flush=True)
              api.disconnect()
              print("Done.", flush=True)
              PY
            ''
          ];
          resources = {
            requests = { cpu = "50m"; memory = "128Mi"; };
            limits   = { cpu = "500m"; memory = "256Mi"; };
          };
        }];
      };
    };
  };
}
