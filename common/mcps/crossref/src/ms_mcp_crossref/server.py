"""CrossRef MCP server — DOI metadata lookup for citation verification.

Tool: crossref_lookup(doi) → canonical {title, authors, journal, year,
publisher, type, url, abstract, reference_count, is_referenced_by_count}.

No API key required. CrossRef asks polite clients to identify themselves
via the User-Agent; CROSSREF_USER_AGENT env overrides the default.
"""
from __future__ import annotations
import os

import httpx
from mcp.server.fastmcp import FastMCP

UA = os.environ.get(
    "CROSSREF_USER_AGENT",
    "ms-researcher-mcp-crossref/0.1",
)
TIMEOUT = httpx.Timeout(15.0, read=20.0)

mcp = FastMCP("crossref")


def _author(a: dict) -> str:
    return " ".join(p for p in [a.get("given", ""), a.get("family", "")] if p).strip()


@mcp.tool()
def crossref_lookup(doi: str) -> dict:
    """Resolve a DOI to canonical citation metadata via CrossRef.

    Call this for EVERY DOI you pick up from pubmed_search or searxng_search.
    If CrossRef returns "not found", drop the citation — do not invent
    a correction or paraphrase a guess. The point of this tool is to
    catch fabricated DOIs before they land in kb/pages/.
    """
    cleaned = doi.strip().removeprefix("https://doi.org/").removeprefix("doi:")
    with httpx.Client(timeout=TIMEOUT, headers={"User-Agent": UA}) as c:
        r = c.get(f"https://api.crossref.org/works/{cleaned}")
        if r.status_code == 404:
            return {"doi": cleaned, "error": "not found"}
        r.raise_for_status()
        msg = r.json().get("message", {})
    container = msg.get("container-title") or []
    issued = (msg.get("issued") or {}).get("date-parts") or [[None]]
    year = issued[0][0] if issued and issued[0] else None
    return {
        "doi": cleaned,
        "title": (msg.get("title") or [""])[0],
        "authors": [_author(a) for a in (msg.get("author") or [])],
        "journal": container[0] if container else "",
        "year": year,
        "issn": msg.get("ISSN"),
        "publisher": msg.get("publisher"),
        "type": msg.get("type"),
        "url": msg.get("URL"),
        "abstract": msg.get("abstract", ""),
        "reference_count": msg.get("references-count", 0),
        "is_referenced_by_count": msg.get("is-referenced-by-count", 0),
    }


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
