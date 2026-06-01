# Declarative bootstrap of Uptime Kuma. Walks config.workloads.uptimeMonitors
# (declared by each workload's uptime.nix), and on every run:
#   1. Creates the initial admin if Kuma is at first-run setup.
#   2. Ensures a `homelab-managed` tag exists.
#   3. Add/update every declared monitor, tagged as managed.
#   4. Deletes any monitor that carries the managed tag but is no longer
#      declared (stale cleanup — won't touch monitors created by hand).
#   5. Syncs the "homelab" public status page with publicGroupList
#      derived from each monitor's `group` field. Group order follows
#      GROUP_ORDER below.
#
# Kuma's API is Socket.IO so we use the community uptime-kuma-api Python
# library, pip-installed at Job runtime in a python:3.11-slim image.
{ config, lib, ... }:

let
  inherit (lib) filterAttrs mapAttrsToList;

  # Bump to force a fresh Job. Embedded in the Job's `name` so K8s sees
  # a brand-new resource each version → guaranteed re-run. Annotation-only
  # bumps are no-ops because Job specs are immutable.
  bootstrapVersion = "7";

  resolveUrl = m:
    if m.url != null
      then m.url
      else "https://${config.sops.placeholder.${m.domainKey}}${m.path}";

  activeMonitors = filterAttrs (_: m: m.enabled) config.workloads.uptimeMonitors;

  monitorList = mapAttrsToList (_: m:
    let
      base = {
        inherit (m) name type interval retryInterval maxretries group tags;
        accepted_statuscodes = m.acceptedStatusCodes;
      };
    in
      if m.type == "http"
      then base // { url = resolveUrl m; }
      else base // { hostname = m.host; port = m.port; }
  ) activeMonitors;

  monitorsJson = builtins.toJSON monitorList;

  adminUser = config.sops.placeholder."uptime-kuma/admin_user";
  adminPwd  = config.sops.placeholder."uptime-kuma/admin_password";
in
{
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

  # Compact JSON inline so YAML `|` indent stays simple. sops-nix
  # resolves placeholders inside the JSON before k3s applies the
  # ConfigMap; the bootstrap Job then mounts /config/monitors.json.
  sops.templates."uptime-kuma/monitors.yaml" = {
    content = ''
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: uptime-kuma-monitors
        namespace: monitoring
      data:
        monitors.json: '${monitorsJson}'
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
      # Versioned name so each `bootstrapVersion` bump spawns a brand-new
      # Job (k8s Job specs are immutable; apply-on-existing is a no-op).
      # Old versions auto-clean via ttlSecondsAfterFinished below.
      name      = "uptime-kuma-bootstrap-v${bootstrapVersion}";
      namespace = "monitoring";
      annotations = {
        "homelab.dobryops.com/bootstrap-version" = bootstrapVersion;
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
            { name = "KUMA_URL"; value = "http://uptime-kuma.monitoring.svc.cluster.local:8097"; }
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

              URL         = os.environ["KUMA_URL"]
              USER        = os.environ["admin_user"]
              PASS        = os.environ["admin_password"]
              MANAGED_TAG = "homelab-managed"

              # Ordered groups for the status page — anything not listed
              # falls to the end alphabetically.
              GROUP_ORDER = ["Media", "Dev", "Ops", "Comms", "Personal",
                             "Dashboard", "Private"]

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

              # Ensure the managed tag exists.
              tags = api.get_tags()
              managed = next((t for t in tags if t["name"] == MANAGED_TAG), None)
              if managed is None:
                  print(f"Creating tag '{MANAGED_TAG}'", flush=True)
                  managed = api.add_tag(name=MANAGED_TAG, color="#3b82f6")
              managed_id = managed["id"]

              with open("/config/monitors.json") as f:
                  declared = json.load(f)
              declared_by_name = {m["name"]: m for m in declared}

              existing = api.get_monitors()
              existing_by_name = {m["name"]: m for m in existing}

              def has_managed_tag(m):
                  return any(t.get("name") == MANAGED_TAG for t in (m.get("tags") or []))

              def common_args(d):
                  base = dict(
                      name          = d["name"],
                      interval      = d["interval"],
                      retryInterval = d["retryInterval"],
                      maxretries    = d["maxretries"],
                  )
                  if d["type"] == "http":
                      base.update(
                          type                 = MonitorType.HTTP,
                          url                  = d["url"],
                          accepted_statuscodes = d["accepted_statuscodes"],
                      )
                  elif d["type"] == "port":
                      base.update(
                          type     = MonitorType.PORT,
                          hostname = d["hostname"],
                          port     = d["port"],
                      )
                  return base

              monitor_ids = {}
              for name, decl in declared_by_name.items():
                  if name in existing_by_name:
                      m = existing_by_name[name]
                      # Update in place
                      args = common_args(decl)
                      args.pop("name", None)  # name is the lookup key
                      api.edit_monitor(m["id"], **args)
                      monitor_ids[name] = m["id"]
                      if not has_managed_tag(m):
                          try:
                              api.add_monitor_tag(managed_id, m["id"], "")
                          except Exception as e:
                              print(f"  tag attach failed for {name}: {e}", flush=True)
                      print(f"  ~ {name} (updated, id={m['id']})", flush=True)
                  else:
                      args = common_args(decl)
                      res = api.add_monitor(**args)
                      new_id = res["monitorID"]
                      try:
                          api.add_monitor_tag(managed_id, new_id, "")
                      except Exception as e:
                          print(f"  tag attach failed for {name}: {e}", flush=True)
                      monitor_ids[name] = new_id
                      print(f"  + {name} (created, id={new_id})", flush=True)

              # Stale: monitor that carries our tag but isn't declared anymore.
              stale = [
                  m for m in existing
                  if has_managed_tag(m) and m["name"] not in declared_by_name
              ]
              for m in stale:
                  print(f"  - {m['name']} (stale, deleting id={m['id']})", flush=True)
                  api.delete_monitor(m["id"])

              # Build status page publicGroupList ordered per GROUP_ORDER.
              def group_weight(g):
                  return GROUP_ORDER.index(g) if g in GROUP_ORDER else len(GROUP_ORDER)

              groups = {}
              for name, decl in declared_by_name.items():
                  groups.setdefault(decl["group"], []).append(monitor_ids[name])

              publicGroupList = sorted(
                  [
                      {
                          "name": g,
                          "weight": group_weight(g),
                          "monitorList": [{"id": mid, "sendUrl": 0} for mid in sorted(ids)],
                      }
                      for g, ids in groups.items()
                  ],
                  key=lambda x: (x["weight"], x["name"]),
              )

              try:
                  api.get_status_page("homelab")
                  print("Status page 'homelab' exists — updating", flush=True)
              except Exception:
                  print("Creating status page 'homelab'", flush=True)
                  api.add_status_page("Homelab", "homelab")

              api.save_status_page(
                  slug            = "homelab",
                  title           = "Homelab",
                  description     = "Auto-managed by workloads.uptimeMonitors",
                  publicGroupList = publicGroupList,
                  showTags        = True,
              )
              print(f"Status page synced ({len(declared)} monitors, {len(groups)} groups).", flush=True)
              api.disconnect()
              print("Done.", flush=True)
              PY
            ''
          ];
          resources = {
            requests = { cpu = "100m"; memory = "128Mi"; };
            # pip install + uptime-kuma-api's socket.io connect both burst
            # close to 1 core. Generous limit per the raise-don't-remove rule.
            limits   = { cpu = "2000m"; memory = "512Mi"; };
          };
        }];
      };
    };
  };
}
