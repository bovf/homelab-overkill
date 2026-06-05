#!/usr/bin/env python3
# mcp-crossref — MCP server wrapping the CrossRef REST API for DOI lookup.
# stdio JSON-RPC; tool: crossref_lookup.
from __future__ import annotations
import json
import os
import sys

import httpx

UA = os.environ.get(
    "CROSSREF_USER_AGENT",
    "ms-researcher-mcp-crossref/0.1 (mailto:ms-researcher@dobryops.com)",
)
TIMEOUT = httpx.Timeout(15.0, read=20.0)


def _author(a: dict) -> str:
    return " ".join(p for p in [a.get("given", ""), a.get("family", "")] if p).strip()


def crossref_lookup(doi: str) -> dict:
    doi = doi.strip().removeprefix("https://doi.org/").removeprefix("doi:")
    with httpx.Client(timeout=TIMEOUT, headers={"User-Agent": UA}) as c:
        r = c.get(f"https://api.crossref.org/works/{doi}")
        if r.status_code == 404:
            return {"doi": doi, "error": "not found"}
        r.raise_for_status()
        msg = r.json().get("message", {})
    container = msg.get("container-title") or []
    issued = (msg.get("issued") or {}).get("date-parts") or [[None]]
    year = issued[0][0] if issued and issued[0] else None
    return {
        "doi": doi,
        "title": (msg.get("title") or [""])[0],
        "authors": [_author(a) for a in (msg.get("author") or [])],
        "journal": container[0] if container else "",
        "year": year,
        "issn": msg.get("ISSN"),
        "publisher": msg.get("publisher"),
        "type": msg.get("type"),
        "url": msg.get("URL"),
        "pmid": next(
            (
                rel.get("id")
                for rel in (msg.get("relation", {}).get("has-preprint") or [])
                if rel.get("id-type") == "pmid"
            ),
            None,
        ),
        "abstract": msg.get("abstract", ""),
        "reference_count": msg.get("references-count", 0),
        "is_referenced_by_count": msg.get("is-referenced-by-count", 0),
    }


TOOLS = [
    {
        "name": "crossref_lookup",
        "description": "Canonical citation metadata for a DOI via the CrossRef REST API. Use after every DOI you pick up from PubMed or SearXNG to verify it resolves and to grab title/authors/journal/year.",
        "inputSchema": {
            "type": "object",
            "properties": {"doi": {"type": "string", "description": "DOI (with or without the 'doi:' / 'https://doi.org/' prefix)."}},
            "required": ["doi"],
        },
    },
]

DISPATCH = {"crossref_lookup": crossref_lookup}


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
            "serverInfo": {"name": "mcp-crossref", "version": "0.1.0"},
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
