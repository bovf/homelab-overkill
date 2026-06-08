---
name: rss-watch
description: Every 6 hours — poll curated Multiple Sclerosis RSS feeds, score credibility, save raw feed data, and process trustworthy items into the KB.
schedule: "0 */6 * * *"
timezone: "Europe/Sofia"
skills:
  - kb-rss-watch
  - kb-research
  - kb-ingest
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

1. Raw JSONL item audit trail under `$KB_ROOT/raw/rss/YYYY_MM_DD/HHMM_items.jsonl`.
2. Candidate report under `$KB_ROOT/raw/rss/YYYY_MM_DD/HHMM_candidates.md`.
3. Query/run report under `$KB_ROOT/queries/rss_watch_YYYY_MM_DD_HHMM.md`.
4. Up to 4 citation-grounded KB pages for high-confidence verified items, with at least one non-trial peer-reviewed item when available.
5. Refresh `$KB_ROOT/pages/Start Here.md` so the published KB front door links to the latest useful pages, the latest digest/report, and `/kb/` for raw file-tree browsing.
6. One `kb-journal` entry with processed/pages/verify/watch/rejected counts.

Credibility rules:

- Peer-reviewed/official/trial-registry sources may be processed immediately
  only when MS-relevant and source facts can be cited.
- Science/news/community items are leads only; verify with PubMed, CrossRef,
  ClinicalTrials.gov, NIH/NINDS, recognized MS societies, or publisher pages
  before writing claims into `pages/`.
- MS Trust/MSAA practical tips may become low/medium-evidence practical pages,
  but must not be framed as individualized treatment advice.
- Reject miracle cures, detox/reversal claims, anti-vaccine narratives,
  supplement/product pitches, sponsored/affiliate material, or unrelated
  neurology. Save reject metadata in the run report; do not summarize it as
  evidence.

Do not post a Matrix message unless something requires urgent human review.
Do not treat large queue/watchlist counts as user-facing news. The Monday digest
will summarize the genuinely useful KB highlights in a readable format.

## Start Here maintenance

After the run report and any page writes, update `$KB_ROOT/pages/Start Here.md`.
Keep it human-facing, not operational. It should include:

- A one-paragraph "Start here" explanation.
- Link to the newest weekly digest/report if one exists.
- A small "Recent updates" list from meaningful pages/reports touched recently.
- Topic sections for clinical research, trials worth watching, practical living,
  biomarkers/monitoring, and treatments/safety when pages exist.
- A "Browse the whole KB" link to `/kb/`, noting that it opens the raw file tree
  (`pages/`, `journals/`, `reports/`, `queries/`, `raw/`).
- An evidence legend explaining peer-reviewed, registry-only, official MS org,
  and news lead/watchlist.

Do not use Logseq wikilinks on this page; prefer normal markdown links and KB
paths so the published web view and raw file-tree view both stay readable.
