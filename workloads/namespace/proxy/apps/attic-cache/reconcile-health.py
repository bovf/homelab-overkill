#!/usr/bin/env python3
"""Reconcile Attic's disabled health check using Pangolin's stock integration API."""
import argparse
import json
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


class RepairError(Exception):
    pass


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *_args, **_kwargs):
        return None  # Never forward the API credential to a redirect destination.


class API:
    def __init__(self, endpoint, token):
        parsed = urllib.parse.urlsplit(endpoint)
        if parsed.username or parsed.password or parsed.query or parsed.fragment:
            raise RepairError("Invalid Pangolin API endpoint.")
        if parsed.scheme != "https" and not (
            parsed.scheme == "http" and parsed.hostname in ("127.0.0.1", "::1", "localhost")
        ):
            raise RepairError("Pangolin API requires HTTPS except for loopback tests.")
        if not token:
            raise RepairError("Pangolin API credential is empty.")
        self.endpoint = endpoint.rstrip("/")
        self.token = token
        self.opener = urllib.request.build_opener(NoRedirect())

    def call(self, method, path, body=None):
        request = urllib.request.Request(
            self.endpoint + path,
            method=method,
            data=json.dumps(body).encode() if body is not None else None,
            headers={"Authorization": "Bearer " + self.token, "Content-Type": "application/json"},
        )
        try:
            with self.opener.open(request, timeout=15) as response:
                result = json.load(response)
        except urllib.error.HTTPError as error:
            route = urllib.parse.urlsplit(path).path
            if error.code in (401, 403):
                reason = "Verify the API credential and listResources/listTargets/updateTarget permissions."
            elif error.code == 400:
                reason = "Request validation failed."
            else:
                reason = "Request failed."
            raise RepairError(
                f"Pangolin API {method} {route} returned HTTP {error.code}. "
                f"{reason} Response details suppressed."
            ) from None
        if result.get("success") is not True or not isinstance(result.get("data"), dict):
            raise RepairError("Pangolin API rejected the request; response details suppressed.")
        return result["data"]


def identifier(value):
    if type(value) is not int or value <= 0:
        raise RepairError("Invalid Pangolin object identifier.")
    return value


def reconcile(api, org_id, resource_key, host, port):
    # Resource lists use page/pageSize; target lists below use limit/offset.
    resources = []
    page = 1
    while True:
        result = api.call(
            "GET", f"/v1/org/{urllib.parse.quote(org_id, safe='')}/resources?pageSize=100&page={page}"
        )
        batch = result["resources"]
        total = result["pagination"]["total"]
        if not isinstance(batch, list) or type(total) is not int or total < 0:
            raise RepairError("Invalid Pangolin resource pagination response.")
        resources.extend(batch)
        if len(resources) >= total:
            break
        if not batch:
            raise RepairError("Pangolin resource pagination ended before all resources were returned.")
        page += 1
    matching = [r for r in resources if r.get("niceId") == resource_key]
    if len(matching) != 1 or matching[0].get("enabled") is not True:
        raise RepairError("Expected one enabled Attic resource; verify blueprint publication.")
    resource_id = identifier(matching[0]["resourceId"])
    path = f"/v1/resource/{resource_id}/targets?limit=1000"
    targets = api.call("GET", path)["targets"]
    if len(targets) != 1:
        raise RepairError("Expected exactly one Attic target; refusing to guess.")
    target = targets[0]
    if (
        target.get("siteType") != "wireguard"
        or target.get("ip") != host
        or target.get("port") != port
        or target.get("enabled") is not True
    ):
        raise RepairError("Attic target does not match its declared Basic WireGuard backend.")
    if target.get("hcEnabled") is not False:
        raise RepairError("Refusing to override an enabled health check; verify blueprint publication.")
    if target.get("hcHealth") in ("unknown", "healthy"):
        return False
    if target.get("hcHealth") != "unhealthy":
        raise RepairError("Unrecognized Attic health state; refusing to modify the target.")
    target_id = identifier(target["targetId"])
    api.call("POST", f"/v1/target/{target_id}", {
        "siteId": identifier(target["siteId"]), "ip": target["ip"], "hcEnabled": False,
    })
    updated = api.call("GET", path)["targets"]
    if len(updated) != 1 or any(updated[0].get(k) != v for k, v in {
        "targetId": target_id, "hcEnabled": False, "hcHealth": "unknown",
    }.items()):
        raise RepairError("Pangolin did not clear Attic's disabled health state.")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("endpoint", "api-key-file", "org-id", "resource", "host"):
        parser.add_argument("--" + name, required=True)
    parser.add_argument("--port", type=int, required=True)
    args = parser.parse_args()
    try:
        api = API(args.endpoint, Path(args.api_key_file).read_text().strip())
        changed = reconcile(api, args.org_id, args.resource, args.host, args.port)
    except RepairError as error:
        parser.exit(1, f"{error}\n")
    except Exception:  # noqa: BLE001 - Unexpected exceptions may contain request credentials.
        parser.exit(1, "Attic health reconciliation failed (I/O, network or response error); details suppressed.\n")
    print("Cleared stale Attic health through Pangolin's stock API." if changed else "Attic disabled health needs no correction.")


if __name__ == "__main__":
    main()
