#!/usr/bin/env python3
# mcp-searxng — MCP server hitting the homelab's SearXNG instance.
# stdio JSON-RPC; tool: searxng_search. No external API, no API key —
# the LAN's own SearXNG handles it. SEARXNG_DOMAIN (e.g. search.dobryops.com)
# is rendered into ~/.hermes/.env by the ms-researcher module.
from __future__ import annotations
import json
import os
import sys

import httpx

DOMAIN = os.environ.get("SEARXNG_DOMAIN", "")
TIMEOUT = httpx.Timeout(15.0, read=20.0)


def searxng_search(query: str, categories: list[str] | None = None, max_results: int = 15) -> dict:
    if not DOMAIN:
        return {"error": "SEARXNG_DOMAIN is not set; cannot reach SearXNG."}
    cats = ",".join(categories) if categories else "general"
    url = f"https://{DOMAIN}/search"
    params = {"q": query, "format": "json", "categories": cats}
    with httpx.Client(timeout=TIMEOUT, follow_redirects=True) as c:
        r = c.get(url, params=params, headers={"Accept": "application/json"})
        r.raise_for_status()
        data = r.json()
    results = []
    for hit in (data.get("results") or [])[:max_results]:
        results.append({
            "title": hit.get("title", ""),
            "url": hit.get("url", ""),
            "content": (hit.get("content") or "").strip(),
            "engine": hit.get("engine", ""),
            "score": hit.get("score"),
        })
    return {
        "query": query,
        "categories": cats,
        "count": len(results),
        "results": results,
        "infoboxes": data.get("infoboxes") or [],
    }


TOOLS = [
    {
        "name": "searxng_search",
        "description": "General-web search via the homelab SearXNG (LAN-private, no API key, no rate limit). Use `categories=['science']` first for research queries, then fall back to `['general']`.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "categories": {
                    "type": "array",
                    "items": {"type": "string", "enum": ["general", "science", "news", "files", "it"]},
                    "default": ["general"],
                },
                "max_results": {"type": "integer", "default": 15, "minimum": 1, "maximum": 50},
            },
            "required": ["query"],
        },
    },
]

DISPATCH = {"searxng_search": searxng_search}


# ─── stdio JSON-RPC framing ──────────────────────────────────────────────────
def send(msg: dict) -> None:
    sys.stdout.write(json.dumps(msg) + "\n")
    sys.stdout.flush()


def reply(req_id, result=None, error=None) -> None:
    msg = {"jsonrpc": "2.0", "id": req_id}
    if error is not None:
        msg["error"] = error
    else:
        msg["result"] = result
    send(msg)


def handle(req: dict) -> None:
    method = req.get("method")
    req_id = req.get("id")
    if method == "initialize":
        reply(req_id, {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "mcp-searxng", "version": "0.1.0"},
        })
    elif method == "notifications/initialized":
        return
    elif method == "tools/list":
        reply(req_id, {"tools": TOOLS})
    elif method == "tools/call":
        params = req.get("params") or {}
        name = params.get("name")
        args = params.get("arguments") or {}
        fn = DISPATCH.get(name)
        if fn is None:
            reply(req_id, error={"code": -32601, "message": f"unknown tool {name!r}"})
            return
        try:
            result = fn(**args)
            reply(req_id, {"content": [{"type": "text", "text": json.dumps(result, ensure_ascii=False)}]})
        except Exception as e:
            reply(req_id, {"content": [{"type": "text", "text": json.dumps({"error": str(e)})}], "isError": True})
    elif req_id is not None:
        reply(req_id, error={"code": -32601, "message": f"unknown method {method!r}"})


def main() -> int:
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except json.JSONDecodeError:
            continue
        handle(req)
    return 0


if __name__ == "__main__":
    sys.exit(main())
