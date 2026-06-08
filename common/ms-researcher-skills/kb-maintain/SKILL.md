---
name: kb-maintain
description: Self-heal the MS knowledgebase layout after RSS watch or weekly digest. Migrates legacy flat files into the V2 date/type structure, refreshes Start Here and Index pages, checks links/frontmatter, and journals the maintenance summary.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [kb, maintenance, self-healing, layout, ms-research]
    category: ms-knowledgebase
    related_skills: [kb-rss-watch, kb-research, kb-journal]
---

# kb-maintain

Self-heal the KB so it stays browseable over months, not just days.

## When to use

- After every `weekly-digest` run.
- After `rss-watch` when pages/reports/queries were written.
- Whenever the user says the KB structure or navigation looks messy.

## Env vars

- `$KB_ROOT` — kb tree root.

## Canonical V2 layout

```text
$KB_ROOT/
  pages/
    Start Here.md
    Index.md
    indexes/
      Clinical Research.md
      Trials.md
      Treatments and Safety.md
      Biomarkers and Monitoring.md
      Practical Living.md
      Reports.md
      2026.md
      2026-06.md
  content/
    studies/YYYY/MM/<slug>.md
    trials/YYYY/MM/<slug>.md
    practical/YYYY/MM/<slug>.md
    reports/YYYY/WNN/weekly_digest_YYYY_WNN.md
    queries/YYYY/MM/<slug>.md
  journals/YYYY/MM/YYYY_MM_DD.md
  raw/rss/YYYY/MM/DD/<HHMM>_items.jsonl
  raw/rss/YYYY/MM/DD/<HHMM>_candidates.md
  raw/manual/YYYY/MM/DD/<slug>.<ext>
```

`pages/` is navigation only. Canonical content goes in `content/`. Raw RSS and
manual ingests stay under `raw/`, date-partitioned.

## Required maintenance pass

### 1. Create required directories

Create missing directories for the current year/month/week:

- `pages/indexes/`
- `content/studies/YYYY/MM/`
- `content/trials/YYYY/MM/`
- `content/practical/YYYY/MM/`
- `content/reports/YYYY/WNN/`
- `content/queries/YYYY/MM/`
- `journals/YYYY/MM/`
- `raw/rss/YYYY/MM/DD/`
- `raw/manual/YYYY/MM/DD/`

### 2. Migrate legacy files non-destructively

Move only when the destination does not already exist. If the destination
exists, compare briefly and keep both by adding `_legacy` or `_2` rather than
overwriting.

Recommended moves:

- `journals/YYYY_MM_DD.md` → `journals/YYYY/MM/YYYY_MM_DD.md`
- `reports/YYYY_WNN.md` or `reports/*digest*.md` → `content/reports/YYYY/WNN/`
- `queries/rss_watch_YYYY_MM_DD_HHMM.md` → `content/queries/YYYY/MM/`
- `queries/*.md` with date in filename → `content/queries/YYYY/MM/`
- `pages/study_*.md` → `content/studies/YYYY/MM/`
- `pages/trial_*.md` → `content/trials/YYYY/MM/`
- `pages/*practical*.md`, MS Trust/MSAA guidance, symptom/living pages → `content/practical/YYYY/MM/`
- `raw/rss/YYYY_MM_DD/` → `raw/rss/YYYY/MM/DD/`
- manual raw files at `raw/<date>_<slug>.*` → `raw/manual/YYYY/MM/DD/`

Use frontmatter `created`, `last_reviewed`, `generated`, or filename dates to
choose `YYYY/MM`; if unknown, use the file mtime in Europe/Sofia.

### 3. Required frontmatter checks

For content pages, ensure frontmatter includes at least:

```yaml
type: study | trial | practical | report | query | concept | drug
status: active | watch | archived | unanswered
created: YYYY-MM-DD
last_reviewed: YYYY-MM-DD
evidence_grade: high | medium | low | registry-only
sources: []
topics: []
```

Do not invent missing sources. If sources are unknown, preserve existing text
and add `sources: []` plus `needs_source_review: true`.

### 4. Link hygiene

- Never write `[[/kb/]]`; it creates the broken page `#/page/kb`.
- Replace broken `/kb/` Logseq links with `https://ms-kb.dobryops.com/#/page/Index` for human navigation.
- Use `https://ms-kb.dobryops.com/kb/` only for the raw file tree.
- Prefer normal markdown links or plain KB paths in index pages.
- Check that links in `Start Here.md`, `Index.md`, and `pages/indexes/*.md` point to existing files or known web routes.

### 5. Refresh navigation pages

Refresh these every run:

- `pages/Start Here.md` — short curated front door.
- `pages/Index.md` — whole-KB human navigation.
- `pages/indexes/Clinical Research.md`
- `pages/indexes/Trials.md`
- `pages/indexes/Treatments and Safety.md`
- `pages/indexes/Biomarkers and Monitoring.md`
- `pages/indexes/Practical Living.md`
- `pages/indexes/Reports.md`
- `pages/indexes/YYYY.md`
- `pages/indexes/YYYY-MM.md`

Index rules:

- Newest first within each section.
- Group by month where lists are long.
- Keep `Start Here.md` short: latest digest + best current links only.
- `Index.md` links to sub-indexes and top current items; it is not a raw dump.
- Sub-indexes may be longer but should still be grouped and scan-friendly.
- Include raw file-tree link only as secondary:
  `Raw file tree: https://ms-kb.dobryops.com/kb/`

### 6. Duplicate checks

Detect duplicates by DOI, PMID, NCT, title slug, and URL. If duplicates exist:

- Keep the richer/newer canonical content file.
- Add a note in the maintenance report.
- Do not delete duplicates automatically unless they are byte-identical; move
  obvious duplicates to `content/duplicates/YYYY/MM/` only if safe.

### 7. Maintenance report

Write a report:

`$KB_ROOT/content/queries/YYYY/MM/kb_maintain_YYYY_MM_DD_HHMM.md`

Include:

- files moved
- indexes refreshed
- broken links found/fixed
- duplicate candidates
- frontmatter fixes
- unresolved issues requiring human review

### 8. Journal

Call `kb-journal` with:

`event: kb-maintain moved=<N>, indexes=<N>, broken_links=<N>, duplicates=<N>`

## Rules

- Non-destructive first. Never overwrite content silently.
- Do not invent sources or medical claims.
- Do not delete raw audit data.
- Keep the KB browseable for humans, not just internally consistent.
- Reference `$KB_ROOT` by name; never paste the absolute value into chat.
