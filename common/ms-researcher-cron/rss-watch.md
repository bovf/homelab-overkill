---
name: rss-watch
description: Every 6 hours — poll curated Multiple Sclerosis RSS feeds, score credibility, save raw feed data, and process trustworthy items into the KB.
schedule: "0 */6 * * *"
timezone: "Europe/Sofia"
skills:
  - kb-rss-watch
  - kb-research
  - kb-ingest
  - kb-maintain
  - kb-journal
---

# Six-hour MS RSS watch

Run `kb-rss-watch` now.

Poll all configured feeds in the skill:

- ScienceDaily MS research
- Nature MS subject feed
- Multiple Sclerosis Journal / SAGE eTOC
- Frontiers Neurology MS/neuroimmunology
- Multiple Sclerosis News Today
- ClinicalTrials.gov new/updated MS studies
- ClinicalTrials.gov recruiting MS studies
- MS Trust
- MSAA

Required outputs for this run:

1. Raw JSONL item audit trail under `$KB_ROOT/raw/rss/YYYY/MM/DD/HHMM_items.jsonl`.
2. Candidate report under `$KB_ROOT/raw/rss/YYYY/MM/DD/HHMM_candidates.md`.
3. Query/run report under `$KB_ROOT/content/queries/YYYY/MM/rss_watch_YYYY_MM_DD_HHMM.md`.
4. Up to 4 citation-grounded KB pages under `$KB_ROOT/content/{studies,trials,practical}/YYYY/MM/` for high-confidence verified items, with at least one non-trial peer-reviewed item when available.
5. Run `kb-maintain` to self-heal layout, migrate legacy flat files, and refresh `$KB_ROOT/pages/Start Here.md` plus `$KB_ROOT/pages/Index.md`.
6. One `kb-journal` entry with processed/pages/verify/watch/rejected counts.

Credibility rules:

- Peer-reviewed/official/trial-registry sources may be processed immediately
  only when MS-relevant and source facts can be cited.
- Science/news/community items are leads only; verify with PubMed, CrossRef,
  ClinicalTrials.gov, NIH/NINDS, recognized MS societies, or publisher pages
  before writing claims into `content/`.
- MS Trust/MSAA practical tips may become low/medium-evidence practical pages,
  but must not be framed as individualized treatment advice.
- Reject miracle cures, detox/reversal claims, anti-vaccine narratives,
  supplement/product pitches, sponsored/affiliate material, or unrelated
  neurology. Save reject metadata in the run report; do not summarize it as
  evidence.

Do not post a Matrix message unless something requires urgent human review.
Do not treat large queue/watchlist counts as user-facing news. The Monday digest
will summarize the genuinely useful KB highlights in a readable format.

## Start Here and Index maintenance

After the run report and any page writes, run `kb-maintain`. It must update
`$KB_ROOT/pages/Start Here.md` and `$KB_ROOT/pages/Index.md`, refresh sub-indexes
under `$KB_ROOT/pages/indexes/`, and migrate legacy flat files into the V2
layout. Keep all navigation pages human-facing, not operational.

`Start Here.md` should include:

- A one-paragraph "Start here" explanation.
- A prominent `KB Index` link to `https://ms-kb.dobryops.com/#/page/Index` for human navigation.
- Link to the newest weekly digest/report if one exists.
- A small "Recent updates" list from meaningful pages/reports touched recently.
- Topic sections for clinical research, trials worth watching, practical living,
  biomarkers/monitoring, and treatments/safety when pages exist.
- Optional raw file tree link to `https://ms-kb.dobryops.com/kb/`, but do not make raw files the primary navigation path.
- An evidence legend explaining peer-reviewed, registry-only, official MS org,
  and news lead/watchlist.

`Index.md` should be the whole-KB navigation page. It must include a prominent
`Start Here` link to `https://ms-kb.dobryops.com/#/page/Start%20Here`. Organize
links by topic: clinical research, trials, treatments/safety,
biomarkers/monitoring, practical living, reports, queries, journals/activity,
and raw files. Include the raw file tree as `https://ms-kb.dobryops.com/kb/`,
but keep the index itself as the main human-browseable entry point.

Do not use `[[/kb/]]`; it creates the broken Logseq page `#/page/kb`. Prefer
normal markdown links, full web URLs, or plain KB paths. For human navigation,
prefer Logseq `#/page/...` web routes over raw `/kb/content/...md` file URLs.
