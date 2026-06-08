"""SearXNG MCP server — hits the homelab's self-hosted SearXNG.

Tool: searxng_search(query, categories=['general'], max_results=15).
No external API, no API key, no rate limit; queries never leave the LAN.

Env: SEARXNG_DOMAIN is required (e.g. "search.<homelab-domain>"). The
ms-researcher module pulls it from the existing
`pangolin/resources/search/domain` sops key and exports it via the
systemd unit's EnvironmentFile.
"""
from __future__ import annotations
import os

import httpx
from mcp.server.fastmcp import FastMCP

DOMAIN = os.environ.get("SEARXNG_DOMAIN", "")
TIMEOUT = httpx.Timeout(15.0, read=20.0)

mcp = FastMCP("searxng")


@mcp.tool()
def searxng_search(
    query: str,
    categories: list[str] | None = None,
    max_results: int = 15,
) -> dict:
    """General-web search via the homelab SearXNG.

    Use `categories=['science']` first for research queries, then fall
    back to `['general']` if the science bucket is thin. SearXNG hits
    are NOT peer-reviewed evidence by themselves — they're leads. The
    cite-or-silent rule still applies: any claim sourced from here must
    point at a real URL, and pages summarizing such results must carry
    `evidence_grade: low` unless the URL belongs to a recognized medical
    source (pubmed.ncbi.nlm.nih.gov, nejm.org, thelancet.com, etc.).
    """
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


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
