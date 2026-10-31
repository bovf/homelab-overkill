#!/usr/bin/env python3
"""Check rendered Attic config and stock-API reconciliation using synthetic data only."""
import copy
import importlib.util
import json
import subprocess
import sys
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import ClassVar

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "workloads/namespace/proxy/apps/attic-cache/reconcile-health.py"
spec = importlib.util.spec_from_file_location("attic_health", SCRIPT)
assert spec is not None and spec.loader is not None
repair = importlib.util.module_from_spec(spec)
spec.loader.exec_module(repair)
EXPR = """
let f = builtins.getFlake (toString ./.);
    e = f.nixosConfigurations.engineer.config;
    p = f.nixosConfigurations.pangolin;
in {
  resource = { inherit (e.workloads.pangolinResources.cache) enabled ssoEnabled viaKernelWg healthcheck; };
  blueprint = e.sops.templates."pangolin-kwg/blueprint.yaml".content;
  monitors = e.sops.templates."uptime-kuma/monitors.yaml".content;
  jobName = e.services.k3s.manifests.uptime-kuma-bootstrap-job.content.metadata.name;
  postStart = e.systemd.services.pangolin-kwg-blueprint-sync.postStart;
  stopIfChanged = e.systemd.services.pangolin-kwg-blueprint-sync.stopIfChanged;
  nativePackage = p.config.services.pangolin.package.drvPath == p.pkgs.fosrl-pangolin.drvPath;
}
"""


def yaml_json(text):
    result = subprocess.run(["yq", "-o=json", ".", "-"], input=text, text=True, capture_output=True, check=True)
    return json.loads(result.stdout)


config = json.loads(subprocess.check_output([
    "nix", "eval", "--offline", "--no-write-lock-file", "--option", "eval-cache", "false",
    "--impure", "--json", "--expr", EXPR,
], cwd=ROOT))
assert config["nativePackage"], "Attic must not require a patched Pangolin package"
resource = config["resource"]
assert resource["enabled"] and resource["viaKernelWg"] and not resource["ssoEnabled"]
assert resource["healthcheck"] is None
cache = yaml_json(config["blueprint"])["public-resources"]["cache"]
assert cache["enabled"] and cache["auth"]["sso-enabled"] is False
assert len(cache["targets"]) == 1
assert cache["targets"][0]["hostname"] == "100.89.128.16"
assert cache["targets"][0]["port"] == 8102
assert "healthcheck" not in cache["targets"][0]
monitors = json.loads(yaml_json(config["monitors"])["data"]["monitors.json"])
monitor = next(m for m in monitors if m["name"] == "Attic Nix Cache")
assert monitor["url"].endswith("/badwater/nix-cache-info")
assert int(config["jobName"].removeprefix("uptime-kuma-bootstrap-v")) >= 16
assert "reconcile-health.py" in config["postStart"] and "--api-key-file" in config["postStart"]
assert config["stopIfChanged"] is False


class FakeAPI:
    def __init__(self):
        self.resources = [{"niceId": "cache", "resourceId": 116, "enabled": True}]
        self.targets = [{
            "targetId": 116, "siteId": 4, "siteType": "wireguard", "ip": "100.89.128.16",
            "port": 8102, "enabled": True, "hcEnabled": False, "hcHealth": "unhealthy",
        }]
        self.posts = []
        self.pages = []
        self.total_override = None
        self.clear_health = True

    def call(self, method, path, body=None):
        parsed = urllib.parse.urlsplit(path)
        if method == "GET" and parsed.path == "/v1/org/test/resources":
            query = urllib.parse.parse_qs(parsed.query)
            assert set(query) == {"pageSize", "page"}, "Native resource API rejects unknown query keys"
            size, page = int(query["pageSize"][0]), int(query["page"][0])
            assert size > 0 and page >= 1
            self.pages.append(page)
            start = size * (page - 1)
            return {
                "resources": copy.deepcopy(self.resources[start:start + size]),
                "pagination": {
                    "total": len(self.resources) if self.total_override is None else self.total_override,
                    "pageSize": size, "page": page,
                },
            }
        if method == "GET" and path == "/v1/resource/116/targets?limit=1000":
            return {"targets": copy.deepcopy(self.targets)}
        assert method == "POST" and path == "/v1/target/116"
        assert body == {"siteId": 4, "ip": "100.89.128.16", "hcEnabled": False}
        self.posts.append(body)
        if self.clear_health:
            self.targets[0]["hcHealth"] = "unknown"
        return {}


def reconcile(api):
    return repair.reconcile(api, "test", "cache", "100.89.128.16", 8102)


api = FakeAPI()
assert reconcile(api)
assert not reconcile(api) and len(api.posts) == 1, "Repeated sync must not rewrite healthy state"
api = FakeAPI()
api.resources = [{"niceId": f"other-{i}", "resourceId": i + 1000, "enabled": True} for i in range(100)] + api.resources
assert reconcile(api) and api.pages == [1, 2], "Attic must be found beyond the first resource page"
for total in (2, -1, "1", False):
    api = FakeAPI()
    api.total_override = total
    try:
        reconcile(api)
        raise AssertionError("Broken pagination was accepted")
    except repair.RepairError:
        assert not api.posts
for state in ("unknown", "healthy"):
    api = FakeAPI()
    api.targets[0]["hcHealth"] = state
    assert not reconcile(api) and not api.posts
for key, value in (("hcEnabled", True), ("siteType", "newt"), ("ip", "192.0.2.5"),
                   ("port", 1234), ("enabled", False), ("siteId", 0), ("targetId", True)):
    api = FakeAPI()
    api.targets[0][key] = value
    try:
        reconcile(api)
        raise AssertionError(f"Unsafe target accepted: {key}")
    except repair.RepairError:
        assert not api.posts
for field in ("resources", "targets"):
    api = FakeAPI()
    getattr(api, field).append(copy.deepcopy(getattr(api, field)[0]))
    try:
        reconcile(api)
        raise AssertionError("Ambiguous target accepted")
    except repair.RepairError:
        assert not api.posts
api = FakeAPI()
api.clear_health = False
try:
    reconcile(api)
    raise AssertionError("Missing postcondition was accepted")
except repair.RepairError:
    assert len(api.posts) == 1


class Handler(BaseHTTPRequestHandler):
    seen: ClassVar[list[str]] = []
    backend: ClassVar[FakeAPI] = FakeAPI()

    def log_message(self, format, *args):
        pass

    def reply(self, status, data=None):
        self.send_response(status)
        if status == 302:
            self.send_header("Location", "/must-not-follow")
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        result = {"success": True, "data": data} if status == 200 else {
            "error": "synthetic-not-a-real-key: server error details",
        }
        self.wfile.write(json.dumps(result).encode())

    def do_GET(self):
        self.seen.append(self.path)
        assert self.headers["Authorization"] == "Bearer synthetic-not-a-real-key"
        parsed = urllib.parse.urlsplit(self.path)
        if parsed.path == "/v1/org/test/resources":
            if set(urllib.parse.parse_qs(parsed.query)) != {"pageSize", "page"}:
                self.reply(400)
            else:
                self.reply(200, self.backend.call("GET", self.path))
        elif parsed.path == "/v1/resource/116/targets":
            self.reply(200, self.backend.call("GET", self.path))
        else:
            self.reply(302 if self.path == "/redirect" else 403)

    def do_POST(self):
        self.seen.append(self.path)
        assert self.headers["Authorization"] == "Bearer synthetic-not-a-real-key"
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        self.reply(200, self.backend.call("POST", self.path, body))


server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
thread = threading.Thread(target=server.serve_forever, daemon=True)
thread.start()
try:
    client = repair.API(f"http://127.0.0.1:{server.server_port}", "synthetic-not-a-real-key")
    for path in ("/forbidden", "/redirect"):
        try:
            client.call("GET", path)
            raise AssertionError("HTTP failure accepted")
        except repair.RepairError as error:
            assert "synthetic-not-a-real-key" not in str(error)
    assert Handler.seen == ["/forbidden", "/redirect"]
    try:
        client.call("GET", "/v1/org/test/resources?limit=1000")
        raise AssertionError("The native API must reject the old invalid query")
    except repair.RepairError as error:
        assert "HTTP 400" in str(error) and "Request validation failed" in str(error)
        assert "/v1/org/test/resources" in str(error) and "permissions" not in str(error)
        assert "synthetic-not-a-real-key" not in str(error)
    assert reconcile(client)
    assert not reconcile(client) and len(Handler.backend.posts) == 1
    assert "/must-not-follow" not in Handler.seen
finally:
    server.shutdown()
    server.server_close()
    thread.join()
print("PASS: native API query validation/pagination, end-to-end HTTP reconciliation, idempotence, scope guards and redaction.")
