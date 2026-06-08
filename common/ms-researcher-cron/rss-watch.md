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
5. One `kb-journal` entry with processed/pages/verify/watch/rejected counts.

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
