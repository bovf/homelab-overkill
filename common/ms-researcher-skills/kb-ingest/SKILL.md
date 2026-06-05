---
name: kb-ingest
description: Save a URL, file path, pasted text, DOI, or PMID into the knowledgebase at $KB_ROOT/raw/. Enriches via the relevant MCP (pubmed/crossref) when input is a DOI or PMID. NON-DESTRUCTIVE — write-only into raw/, never into pages/.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [kb, ingest, raw, ms-research]
    category: ms-knowledgebase
    related_skills: [kb-research, kb-journal]
---

# kb-ingest

Save an artifact into the knowledgebase. **Raw only** — do not write to
`pages/` from this skill; use `kb-research` for that.

## When to use

User says one of:
- "ingest this link: https://..."
- "save this PDF for later: /path/to/file.pdf"
- "remember this: <pasted text>"
- "look up DOI 10.1056/NEJMoa1601277"
- "look up PMID 28002679"

## Env vars

- `$KB_ROOT` — kb tree root (`/var/lib/ms-researcher/kb` on engineer).

## How

Slug the date as `YYYY_MM_DD` (UTC). Slug the rest from input:

1. **URL** — `curl -fsSL --max-time 15 -o $KB_ROOT/raw/<date>_<slug>.<ext>`.
   Sniff content-type for `.html`, `.pdf`, `.txt`. If pubmed.ncbi.nlm.nih.gov,
   extract the PMID from the URL and ALSO call `pubmed.pubmed_fetch(pmid)`
   to save a structured `<date>_<slug>.pubmed.json` alongside.
2. **File path** — copy with `install -m 0640` into raw/. Keep original
   extension. If `.pdf` and the title is not in the filename, leave it as is.
3. **Pasted text** — write to `<date>_<slug>.md` with a single-line
   frontmatter (`source: pasted, accessed: <date>`).
4. **DOI** — call `crossref.crossref_lookup(doi)`. Save the full JSON to
   `<date>_doi_<slug>.crossref.json`. If `crossref` returns a PMID,
   also call `pubmed.pubmed_fetch(pmid)` and save its result.
5. **PMID** — call `pubmed.pubmed_fetch(pmid)`. Save to
   `<date>_pmid_<pmid>.pubmed.json`. If a DOI is in the response, ALSO
   call `crossref.crossref_lookup(doi)` and save that.

Then call `kb-journal` with `event: ingested <slug>` so the weekly digest
sees it.

## Slug rules

- Lowercase, ASCII, `_` as separator.
- Strip articles and punctuation.
- Cap at 60 chars.
- Examples:
  - `https://www.nejm.org/doi/full/10.1056/NEJMoa1601277` → `nejm_ocrelizumab_opera_2017`
  - PMID 28002679 → `pmid_28002679` (the underlying paper is found via the JSON later)

## Output format for the user

```
✓ Ingested: <kind> → kb/raw/<filename>
  Source:    <url|path|"pasted text">
  Enriched:  <yes/no — list the .json sidecar files if any>
  Next:      `research this` to extract findings into kb/pages/<slug>.md
```

If the fetch fails, say so verbatim. Don't retry.

```
✗ Ingest failed (<reason>):
  <error body>
```

## Rules

- Do NOT extract claims here. This is a save-raw step.
- Do NOT overwrite an existing `<date>_<slug>` file — append `_2`, `_3`
  as a disambiguator.
- Reference `$KB_ROOT` by name; never paste the value into chat.
- If the URL is behind a paywall and the fetch returns an HTML preview
  page, save it anyway and flag in the output: `note: paywalled — only
  the preview was saved.`
- If you can't reach the network (MCP error, curl timeout), do not
  fabricate the file. Report the failure.
