"""PubMed MCP server — wraps NCBI E-utilities for the ms-researcher agent.

Tools:
  pubmed_search(query, max_results=20) — esearch+esummary, returns
    list of {pmid, title, journal, year, authors, doi}.
  pubmed_fetch(pmid) — efetch XML parse, returns full
    {title, journal, year, doi, authors, abstract, mesh_terms}.

Auth: anonymous works (3 req/s cap). Set PUBMED_API_KEY env for 10 req/s.
"""
from __future__ import annotations
import os
import xml.etree.ElementTree as ET

import httpx
from mcp.server.fastmcp import FastMCP

EUTILS = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
API_KEY = os.environ.get("PUBMED_API_KEY", "")
EMAIL   = os.environ.get("PUBMED_EMAIL", "")
TOOL    = "ms-researcher-mcp-pubmed/0.1"
TIMEOUT = httpx.Timeout(15.0, read=20.0)

mcp = FastMCP("pubmed")


def _params(**extra) -> dict:
    p = {"tool": TOOL}
    if EMAIL:
        p["email"] = EMAIL
    if API_KEY:
        p["api_key"] = API_KEY
    p.update(extra)
    return p


@mcp.tool()
def pubmed_search(query: str, max_results: int = 20) -> dict:
    """Search PubMed. Returns list of {pmid, title, journal, year, authors, doi}.

    The query supports MeSH terms, field tags, and boolean operators
    (e.g. `multiple sclerosis[mesh] AND ocrelizumab[ti]`).
    Use this as the FIRST step for any medical-evidence question.
    """
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


@mcp.tool()
def pubmed_fetch(pmid: str) -> dict:
    """Fetch full record for a PMID. Returns title, journal, year, doi,
    authors, abstract, and mesh_terms.

    Call after pubmed_search whenever you need the abstract (for citation
    or to verify the paper actually says what the title suggests). Drop
    any claim whose underlying abstract you haven't read here.
    """
    with httpx.Client(timeout=TIMEOUT) as c:
        r = c.get(
            f"{EUTILS}/efetch.fcgi",
            params=_params(db="pubmed", id=str(pmid), retmode="xml"),
        )
        r.raise_for_status()
        text = r.text
    root = ET.fromstring(text)
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


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
