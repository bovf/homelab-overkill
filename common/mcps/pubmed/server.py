#!/usr/bin/env python3
# mcp-pubmed — MCP server wrapping NCBI E-utilities (PubMed).
# stdio JSON-RPC; tools: pubmed_search, pubmed_fetch.
from __future__ import annotations
import json
import os
import sys
import xml.etree.ElementTree as ET

import httpx

EUTILS = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
API_KEY = os.environ.get("PUBMED_API_KEY", "")
EMAIL   = os.environ.get("PUBMED_EMAIL", "ms-researcher@dobryops.com")
TOOL    = "ms-researcher-mcp-pubmed/0.1"

TIMEOUT = httpx.Timeout(15.0, read=20.0)


def _params(**extra):
    p = {"tool": TOOL, "email": EMAIL}
    if API_KEY:
        p["api_key"] = API_KEY
    p.update(extra)
    return p


def pubmed_search(query: str, max_results: int = 20) -> dict:
    with httpx.Client(timeout=TIMEOUT) as c:
        r = c.get(
            f"{EUTILS}/esearch.fcgi",
            params=_params(db="pubmed", term=query, retmax=max_results, retmode="json"),
        )
        r.raise_for_status()
        data = r.json().get("esearchresult", {})
        pmids = data.get("idlist", [])
        if not pmids:
            return {"count": 0, "results": []}
        s = c.get(
            f"{EUTILS}/esummary.fcgi",
            params=_params(db="pubmed", id=",".join(pmids), retmode="json"),
        )
        s.raise_for_status()
        summaries = s.json().get("result", {})
        out = []
        for pmid in pmids:
            rec = summaries.get(pmid, {})
            out.append({
                "pmid": pmid,
                "title": rec.get("title", "").strip(),
                "journal": rec.get("fulljournalname") or rec.get("source", ""),
                "year": (rec.get("pubdate", "") or "")[:4],
                "authors": [a.get("name", "") for a in rec.get("authors", [])[:6]],
                "doi": next(
                    (x.get("value") for x in rec.get("articleids", []) if x.get("idtype") == "doi"),
                    None,
                ),
            })
        return {"count": int(data.get("count", len(out))), "results": out}


def pubmed_fetch(pmid: str) -> dict:
    with httpx.Client(timeout=TIMEOUT) as c:
        r = c.get(
            f"{EUTILS}/efetch.fcgi",
            params=_params(db="pubmed", id=str(pmid), retmode="xml"),
        )
        r.raise_for_status()
        root = ET.fromstring(r.text)
        article = root.find(".//PubmedArticle")
        if article is None:
            return {"pmid": pmid, "error": "not found"}

        def txt(path: str, el=article) -> str:
            node = el.find(path)
            return "".join(node.itertext()).strip() if node is not None else ""

        abstract_parts = []
        for ab in article.findall(".//Abstract/AbstractText"):
            label = ab.get("Label")
            chunk = "".join(ab.itertext()).strip()
            abstract_parts.append(f"{label}: {chunk}" if label else chunk)
        return {
            "pmid": pmid,
            "title": txt(".//ArticleTitle"),
            "journal": txt(".//Journal/Title"),
            "year": txt(".//PubDate/Year") or txt(".//PubDate/MedlineDate")[:4],
            "doi": next(
                (
                    "".join(e.itertext()).strip()
                    for e in article.findall(".//ArticleId")
                    if e.get("IdType") == "doi"
                ),
                None,
            ),
            "authors": [
                f"{txt('LastName', a)} {txt('Initials', a)}".strip()
                for a in article.findall(".//AuthorList/Author")
            ],
            "abstract": "\n\n".join(p for p in abstract_parts if p),
            "mesh_terms": [
                txt("DescriptorName", m)
                for m in article.findall(".//MeshHeadingList/MeshHeading")
            ],
        }


TOOLS = [
    {
        "name": "pubmed_search",
        "description": "Search PubMed via NCBI E-utilities. Returns list of {pmid, title, journal, year, authors, doi}.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "PubMed query (supports MeSH terms, field tags, boolean operators)."},
                "max_results": {"type": "integer", "default": 20, "minimum": 1, "maximum": 100},
            },
            "required": ["query"],
        },
    },
    {
        "name": "pubmed_fetch",
        "description": "Fetch full metadata + abstract for a PMID. Returns {pmid, title, journal, year, doi, authors, abstract, mesh_terms}.",
        "inputSchema": {
            "type": "object",
            "properties": {"pmid": {"type": "string"}},
            "required": ["pmid"],
        },
    },
]

DISPATCH = {"pubmed_search": pubmed_search, "pubmed_fetch": pubmed_fetch}


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
            "serverInfo": {"name": "mcp-pubmed", "version": "0.1.0"},
        })
    elif method == "notifications/initialized":
        return  # no response for notifications
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
