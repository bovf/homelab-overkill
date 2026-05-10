#!/usr/bin/env python3
"""
Tiny Prometheus exporter for k3s local-path PVC actual disk usage.

Walks STORAGE_PATH expecting subdirectories named <pv>_<namespace>_<pvc>,
runs `du -sb` on each, exposes the result as a Prometheus gauge. Cached
in-memory; refreshed every SCAN_INTERVAL seconds in the background.
"""
import os
import time
import threading
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

STORAGE_PATH = Path(os.environ.get("STORAGE_PATH", "/data/storage"))
PORT = int(os.environ.get("PORT", "9101"))
SCAN_INTERVAL = int(os.environ.get("SCAN_INTERVAL", "300"))


class State:
    lock = threading.Lock()
    cache: dict = {}
    last_scan = 0.0
    last_scan_duration = 0.0
    scan_errors = 0


def escape_label(s: str) -> str:
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')


def scan() -> None:
    start = time.time()
    new_cache: dict = {}
    if not STORAGE_PATH.exists():
        with State.lock:
            State.scan_errors += 1
        return
    for entry in STORAGE_PATH.iterdir():
        if not entry.is_dir():
            continue
        parts = entry.name.split("_", 2)
        if len(parts) != 3 or not parts[0].startswith("pvc-"):
            continue
        pv, ns, pvc = parts
        try:
            out = subprocess.check_output(
                ["du", "-sb", str(entry)],
                stderr=subprocess.DEVNULL,
                timeout=600,
            )
            size = int(out.split()[0])
            new_cache[(ns, pvc, pv)] = size
        except Exception:
            continue
    duration = time.time() - start
    with State.lock:
        State.cache = new_cache
        State.last_scan = time.time()
        State.last_scan_duration = duration


def scan_loop() -> None:
    while True:
        try:
            scan()
        except Exception:
            with State.lock:
                State.scan_errors += 1
        time.sleep(SCAN_INTERVAL)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args, **kwargs):
        pass

    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return
        with State.lock:
            cache = dict(State.cache)
            last_scan = State.last_scan
            duration = State.last_scan_duration
            errs = State.scan_errors
        lines = []
        lines.append("# HELP local_path_pvc_used_bytes Actual disk usage of a k3s local-path PVC (du -sb)")
        lines.append("# TYPE local_path_pvc_used_bytes gauge")
        for (ns, pvc, pv), size in cache.items():
            lines.append(
                'local_path_pvc_used_bytes{namespace="%s",persistentvolumeclaim="%s",pv="%s"} %d'
                % (escape_label(ns), escape_label(pvc), escape_label(pv), size)
            )
        lines.append("# HELP local_path_pvc_last_scan_timestamp Unix timestamp of last successful scan")
        lines.append("# TYPE local_path_pvc_last_scan_timestamp gauge")
        lines.append("local_path_pvc_last_scan_timestamp %f" % last_scan)
        lines.append("# HELP local_path_pvc_last_scan_duration_seconds Wall time of last scan")
        lines.append("# TYPE local_path_pvc_last_scan_duration_seconds gauge")
        lines.append("local_path_pvc_last_scan_duration_seconds %f" % duration)
        lines.append("# HELP local_path_pvc_scan_errors_total Cumulative scan errors")
        lines.append("# TYPE local_path_pvc_scan_errors_total counter")
        lines.append("local_path_pvc_scan_errors_total %d" % errs)
        body = ("\n".join(lines) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    # First scan runs in the background so /metrics comes up immediately.
    # Until the first scan finishes the gauge will be empty.
    threading.Thread(target=scan_loop, daemon=True).start()
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
