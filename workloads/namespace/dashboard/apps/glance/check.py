#!/usr/bin/env python3
"""Check Glance service coverage without decrypting secrets; --icons checks public CDNs."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import subprocess
import urllib.request
import xml.etree.ElementTree as ET


def run(*args, text=None):
    return subprocess.run(
        args, input=text, text=True, capture_output=True, check=True,
        cwd=Path(__file__).resolve().parents[5], timeout=120,
    ).stdout


def widgets(page):
    pending = [w for column in page["columns"] for w in column["widgets"]]
    while pending:
        widget = pending.pop()
        yield widget
        pending.extend(widget.get("widgets", []))


def check_icon(icon):
    value = icon.removeprefix("auto-invert ")
    if value.startswith("/assets/"):
        assert (Path(__file__).parent / value.removeprefix("/assets/")).is_file(), icon
        return
    prefix, _, slug = value.partition(":")
    name, _, ext = slug.partition(".")
    ext = ext if ext in {"svg", "png", "webp"} else "svg"
    # Glance v0.8.6 customIconField URL expansion, not the Simple Icons website.
    paths = {
        "si": f"npm/simple-icons@latest/icons/{name}.svg",
        "mdi": f"npm/@mdi/svg@latest/svg/{name}.svg",
        "sh": f"gh/selfhst/icons@main/{ext}/{name}.{ext}",
        "di": f"gh/homarr-labs/dashboard-icons/{ext}/{name}.{ext}",
    }
    url = "https://cdn.jsdelivr.net/" + paths[prefix] if prefix in paths else value
    assert url.startswith("https://"), f"Unsupported icon: {icon}"
    try:
        with urllib.request.urlopen(url, timeout=20) as response:
            data = response.read(1_000_001)
            assert len(data) <= 1_000_000, "image exceeds 1 MB"
            assert response.headers.get_content_type().startswith("image/"), "not an image"
            if url.endswith(".svg"):
                assert ET.fromstring(data).tag == "{http://www.w3.org/2000/svg}svg", "not an SVG"
    except Exception as error:
        raise RuntimeError(f"Icon {icon}: {error}") from error


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--icons", action="store_true", help="also fetch public icon URLs")
    args = parser.parse_args()
    evaluated = json.loads(run(
        "nix", "eval", "--offline", "--no-write-lock-file", "--json",
        ".#nixosConfigurations.engineer.config", "--apply", """c: {
          manifest = c.sops.templates."glance/config.yaml".content;
          placeholders = c.sops.placeholder;
          resources = builtins.mapAttrs (_: r: {
            inherit (r) protocol domainKey enabled lanIP;
          }) c.workloads.pangolinResources;
        }""",
    ))
    secret = json.loads(run("yq", "-o=json", ".", "-", text=evaluated["manifest"]))
    config = json.loads(run("yq", "-o=json", ".", "-", text=secret["stringData"]["glance.yml"]))
    assert [p["name"] for p in config["pages"]] == ["Home", "Mobile"], "Unexpected pages"
    mobile = config["pages"][1]
    assert mobile.get("width") == "slim", "Mobile must remain slim"
    mobile_urls = {link["url"] for w in widgets(mobile) if w["type"] == "bookmarks"
                   for group in w["groups"] for link in group["links"]}
    for key in ["ms_researcher_kb", "sparkyfitness", "romm"]:
        domain_key = evaluated["resources"][key]["domainKey"]
        assert "https://" + evaluated["placeholders"][domain_key] in mobile_urls, f"Missing Mobile shortcut: {key}"
    home = list(widgets(config["pages"][0]))
    media = next(w for w in home if w["type"] == "group")
    assert [w["title"] for w in media["widgets"]] == [
        "Media", "Library", "Streams", "TV", "Movies", "Requests", "Indexers",
    ], "Media tabs missing or reordered"
    links = [link for w in home if w["type"] == "bookmarks"
             for group in w["groups"] for link in group["links"]]
    # Glance itself and API/client-only resources are deliberately not launchers.
    excluded = {"glance", "cache", "matrix", "minio", "registry"}
    covered = 0
    for key, resource in evaluated["resources"].items():
        if (key in excluded or resource["protocol"] != "http"
                or not (resource["enabled"] or resource["lanIP"])):
            continue
        domain = evaluated["placeholders"][resource["domainKey"]]
        matches = [link for link in links if link["url"] == "https://" + domain]
        assert len(matches) == 1, f"Missing/duplicate Home shortcut: {key}"
        if not resource["enabled"]:
            assert "(LAN)" in matches[0]["title"], f"Missing LAN label: {key}"
        covered += 1
    icons = {link["icon"] for page in config["pages"] for w in widgets(page)
             if w["type"] == "bookmarks" for group in w["groups"] for link in group["links"]}
    for icon in icons:
        if "/assets/" in icon:
            check_icon(icon)
    if args.icons:
        with ThreadPoolExecutor(max_workers=4) as pool:
            list(pool.map(check_icon, sorted(icons)))
    print(f"PASS: {covered} service shortcuts, Home media tabs, Mobile and local icons"
          + (f"; {len(icons)} icon references verified" if args.icons else " (CDN checks skipped; use --icons)"))


if __name__ == "__main__":
    main()
