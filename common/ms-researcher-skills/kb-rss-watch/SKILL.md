---
name: kb-rss-watch
description: Poll trusted Multiple Sclerosis RSS feeds, score credibility, save raw items, filter low-quality material, and promote high-value items into citation-grounded KB processing.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [kb, rss, monitoring, ms-research, credibility]
    category: ms-knowledgebase
    related_skills: [kb-ingest, kb-research, kb-journal]
---

# kb-rss-watch

Poll the curated MS feed set, score items for credibility, save a raw audit
trail, and process only items that pass the evidence gate.

This skill is for scheduled runs. It is deliberately conservative: feeds are
leads, not evidence. Peer-reviewed/official items may become pages; news and
patient-org items are saved and queued unless they can be verified.

## When to use

- The `rss-watch` cron job runs every 6 hours.
- The user asks to refresh MS news/trials/tips now.

## Env vars

- `$KB_ROOT` — kb tree root (`/var/lib/ms-researcher/kb` on engineer).

## Feed registry and source credibility

Use exactly this curated feed list.

| id | source | url | class | base_trust | auto_promote |
|---|---|---|---|---:|---|
| sciencedaily_ms | ScienceDaily MS research | `https://www.sciencedaily.com/rss/health_medicine/multiple_sclerosis.xml` | science-news | 55 | no — verify via PubMed first |
| nature_ms | Nature MS subject feed | `https://www.nature.com/subjects/multiple-sclerosis.rss` | publisher/portfolio | 85 | yes when article is MS-relevant |
| msj_sage | Multiple Sclerosis Journal / SAGE eTOC | `https://journals.sagepub.com/action/showFeed?type=etoc&feed=rss&jc=msj` | peer-reviewed-journal | 90 | yes |
| frontiers_neuro_ms | Frontiers Neurology MS/neuroimmunology | `https://www.frontiersin.org/journals/neurology/rss?section=multiple-sclerosis-and-neuroimmunology` | peer-reviewed-journal | 80 | yes, but verify DOI when present |
| ms_news_today | Multiple Sclerosis News Today | `https://multiplesclerosisnewstoday.com/feed/` | community/news | 45 | no — lead only |
| ctgov_ms_new | ClinicalTrials.gov — new/updated MS studies | `https://clinicaltrials.gov/ct2/results/rss.xml?cond=Multiple+Sclerosis` | official-trial-registry | 90 | yes as trial-status page |
| ctgov_ms_recruiting | ClinicalTrials.gov — recruiting MS studies | `https://clinicaltrials.gov/ct2/results/rss.xml?cond=Multiple+Sclerosis&recrs=a` | official-trial-registry | 90 | yes as trial-status page |
| ms_trust | MS Trust | `https://www.mstrust.org.uk/rss.xml` | patient-org/practical | 65 | only practical/tips pages, no treatment claims |
| msaa | MSAA | `https://mymsaa.org/feed/` | patient-org/practical | 60 | only practical/tips pages, no treatment claims |

## Credibility scoring

For each item, compute a 0–100 `credibility_score` and a `processing_decision`.

Start with `base_trust` from the feed table, then apply modifiers:

### Positive modifiers

- `+10` if URL is on an official or peer-reviewed domain:
  `clinicaltrials.gov`, `pubmed.ncbi.nlm.nih.gov`, `nature.com`,
  `journals.sagepub.com`, `frontiersin.org`, `nih.gov`, `ninds.nih.gov`,
  `nationalmssociety.org`, `msif.org`, `mstrust.org.uk`, `mymsaa.org`.
- `+10` if title/summary contains DOI, PMID, NCT number, randomized, phase 2,
  phase 3, trial, meta-analysis, systematic review, guideline, registry.
- `+5` if the item is about MS-specific research, MS treatment safety,
  relapse/disability outcomes, MRI outcomes, clinical trial status, or
  practical day-to-day living with MS.

### Negative modifiers

- `-35` if it claims or implies a cure, guaranteed reversal, detox, miracle,
  secret protocol, anti-vaccine narrative, or supplement/product pitch.
- `-20` if it is primarily opinion, personal story, sponsored content,
  fundraising, generic wellness, affiliate/purchase content, or unrelated
  neurology.
- `-15` if there is no clear MS relevance in title/summary.
- `-10` if the source is news/community and no DOI/PMID/NCT/official source can
  be found.

Clamp to 0–100.

## Decision gates

- `process_now`: `score >= 80` and source class is peer-reviewed, publisher,
  or official trial registry.
- `verify_then_process`: `score >= 65` but source is news/community/patient-org,
  or the item lacks DOI/PMID/NCT. Search PubMed first; process only if a
  PMID/DOI/NCT/official page verifies the item.
- `queue_only`: `45 <= score < 65`. Save raw and candidate record; do not write
  claims into pages.
- `reject`: `score < 45` or any miracle-cure/product-pitch flag. Save a brief
  reject record only; do not summarize as evidence.

## Run procedure

### 1. Prepare directories

Create these if missing:

```bash
$KB_ROOT/raw/rss/YYYY_MM_DD/
$KB_ROOT/queries/
$KB_ROOT/pages/
$KB_ROOT/journals/
```

Use Europe/Sofia local date/time for filenames:

- Raw items JSONL: `$KB_ROOT/raw/rss/YYYY_MM_DD/HHMM_items.jsonl`
- Candidate report: `$KB_ROOT/raw/rss/YYYY_MM_DD/HHMM_candidates.md`
- Query/run report: `$KB_ROOT/queries/rss_watch_YYYY_MM_DD_HHMM.md`
- Seen ledger: `$KB_ROOT/raw/rss/seen_urls.txt`

### 2. Fetch and parse feeds

Use `curl -LfsS --max-time 25` or Python stdlib. Do not require third-party
Python packages. Parse RSS/Atom fields:

- `feed_id`, `feed_title`, `item_title`, `url`, `published`, `updated`,
  `summary`, `authors` if present.

Normalize each URL by stripping obvious tracking query keys (`utm_*`, `fbclid`,
`gclid`) and fragments. If normalized URL appears in `seen_urls.txt`, skip it.

If a feed fetch fails, record it in the run report and continue.

### 3. Score and filter

For every new item:

1. Score it using the table and modifiers above.
2. Assign `processing_decision`.
3. Write one JSON object per item to the raw JSONL with:
   `fetched_at`, `feed_id`, `source`, `source_class`, `base_trust`,
   `credibility_score`, `processing_decision`, `title`, `url`, `published`,
   `summary`, `signals`, `red_flags`.
4. Append accepted/queued/rejected sections to `HHMM_candidates.md`.
5. Append every non-rejected URL to `seen_urls.txt` only after it is recorded.

### 4. Processing budget

Avoid noisy or expensive scheduled runs:

- Process at most **5** items per run.
- Of those, auto-write/update at most **3** KB pages per run.
- Prefer, in order:
  1. ClinicalTrials.gov recruiting/new trial changes.
  2. SAGE MSJ / Nature / Frontiers peer-reviewed research.
  3. ScienceDaily items that verify to a PubMed PMID/DOI.
  4. MS Trust/MSAA practical items with concrete official guidance.
  5. MS News Today items only if independently verified by PubMed or an
     official trial/source page.

### 5. Trigger KB processing

For each selected `process_now` / verified item:

- **ClinicalTrials.gov item**: write or update a `type: trial` page under
  `$KB_ROOT/pages/trial_<nct_or_slug>.md`. Cite the ClinicalTrials.gov URL.
  State only registry facts: status, condition, intervention, phase, enrollment,
  locations if visible. Do not infer efficacy.

- **Peer-reviewed/publisher item**: search PubMed with the exact title first.
  If a PMID is found, fetch it via `pubmed.pubmed_fetch(pmid)`, verify DOI via
  `crossref.crossref_lookup(doi)`, then create/update a page using the
  `kb-research` standards. If PubMed cannot verify it, write only to candidate
  report; do not create a claims page.

- **Science/news/community item**: treat as a lead. Search PubMed and/or
  SearXNG for an official primary source. Promote only if verified by PMID, DOI,
  ClinicalTrials.gov, NIH/NINDS, recognized MS society, or publisher page.
  Otherwise leave it as `queue_only`.

- **Practical living/tips item**: only from MS Trust/MSAA or similarly official
  patient organizations. Write a practical page only when the advice is clearly
  non-prescriptive and source-attributed. Include frontmatter
  `evidence_grade: low` or `medium`; include an explicit note:
  "Practical guidance source, not individualized medical advice. Discuss care
  decisions with the MS clinician."

### 6. Run report

Always write `$KB_ROOT/queries/rss_watch_YYYY_MM_DD_HHMM.md` with:

```markdown
---
type: query
source: rss-watch
generated: YYYY-MM-DD HH:MM Europe/Sofia
feeds_ok: N
feeds_failed: N
items_seen: N
items_new: N
processed: N
pages_written: N
queued: N
rejected: N
---

# RSS watch YYYY-MM-DD HH:MM

## Feeds failed
- ...

## Processed now
- [[page_slug]] — source, score, why it passed

## Queued for human review
- title — source, score, URL, why queued

## Rejected / low credibility
- title — source, score, red flags
```

### 7. Journal

Call `kb-journal` with:

`event: rss-watch processed=<N>, pages=<N>, queued=<N>, rejected=<N>`

## Rules

- Never treat a news/community feed item as medical evidence by itself.
- Never write treatment recommendations.
- Never write miracle-cure/supplement/product-pitch claims into `pages/`
  except as a flagged low-evidence warning page when a human explicitly asks.
- Every page written must cite DOI/PMID/NCT/URL in frontmatter and footnotes.
- Keep raw records even when no page is written; the KB should be auditable.
- Reference `$KB_ROOT` by name in chat/reports; do not paste the absolute value
  in Matrix replies.
