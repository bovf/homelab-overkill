---
name: weekly-digest
description: Every Monday 08:00 (Europe/Sofia) — publish a plain, reader-friendly MS weekly field update for Dobry and GF.
schedule: "0 8 * * MON"
timezone: "Europe/Sofia"
delivery:
  channel: matrix
  target: env:MATRIX_HOME_ROOM
---

# This week in MS

It is Monday morning. Write a plain, calm, easy-to-skim weekly update for two
people who want to stay informed about MS clinical research and living better
with MS.

Think: a small personal newsletter, not a lab meeting and not an ops report.
The reader should be able to scan it in 2 minutes over coffee.

## Hard rendering rules for Matrix

Matrix chat does not render Logseq wikilinks or markdown footnotes well.
For the Matrix message:

- Do **not** use `[[page_name]]`.
- Do **not** use footnotes like `[^1]`.
- Do **not** use emojis.
- Do **not** lead with queue counts, feed counts, or internal job mechanics.
- Use plain titles and short paragraphs/bullets.
- When pointing to KB material, use a simple path in parentheses:
  `(KB: kb/pages/<slug>.md)` or `(Full digest: kb/reports/<YYYY>_W<NN>.md)`.
- Always include web navigation links when the KB web UI is available:
  - Start Here: `https://ms-kb.dobryops.com/#/page/Start%20Here`
  - Browse whole KB: `https://ms-kb.dobryops.com/kb/`
  - Full digest in Logseq: `https://ms-kb.dobryops.com/#/page/<URL-encoded report page title or slug>`
- If a future `LOGSEQ_BASE_URL` env var exists, use it instead of the hardcoded
  `https://ms-kb.dobryops.com` base. Until then, use the hardcoded web URL plus
  KB paths.

## Inputs you must read, in order

1. `$KB_ROOT/journals/` — files with `last-modified` in the last 7 days.
2. `$KB_ROOT/pages/` — files with `last-modified` in the last 7 days. Read
   frontmatter for `type`, `evidence_grade`, `sources`, and `last_reviewed`.
3. `$KB_ROOT/reports/` — last week's digest, if present, so you do not repeat
   unchanged items.
4. `$KB_ROOT/queries/rss_watch_*.md` from the last 7 days — use only for
   context. Do not present feed/backlog totals as news.
5. `$KB_ROOT/raw/rss/YYYY_MM_DD/*_candidates.md` from the last 7 days only for
   watchlist context. Do not cite raw RSS as evidence unless it points to an
   official source/DOI/PMID/NCT.

If a week has zero meaningful activity, deliver exactly:

> "No major MS research updates made it into the KB this week. The watcher is still running, and we will keep tracking new studies, trials, and practical guidance."

Do not pad. Do not invent activity.

## Selection rules

Pick items that are useful for humans, not merely new in a feed.

Prefer:

1. Peer-reviewed or DOI/PMID-backed pages.
2. ClinicalTrials.gov/NCT pages that represent meaningful trial movement.
3. Safety updates, treatment evidence, biomarkers, rehabilitation, lifestyle,
   symptom-management, or care-navigation items from recognized sources.
4. Practical living items from MS Trust/MSAA/NMSS/MSIF when clearly sourced and
   non-prescriptive.

Down-rank or omit:

- Generic feed noise.
- Queue-only items that were not verified.
- Registry entries that do not change practical understanding.
- Repeated items already highlighted last week.
- Promotional/sponsored/miracle-cure/product-pitch material.

## Output: write the report file

Path: `$KB_ROOT/reports/<YYYY>_W<NN>.md`, ISO week number two digits.

The report file may use markdown links/KB paths, but still keep it readable.
Prefer paths over Logseq wikilinks until we have a hosted Logseq URL.

Use this template:

```markdown
---
type: report
period: "<YYYY>-W<NN>"
generated: <YYYY-MM-DD HH:MM:SS Europe/Sofia>
pages_touched: <integer>
queries_answered: <integer>
new_trials: <integer>
watchlist_items: <integer>
---

# This week in MS — Week <NN> of <YYYY>

## The short version

3–5 plain bullets. No internal queue statistics. Example tone:

- No breakthrough this week, but three new MS trial records were added to the KB.
- The most practical item is a switch study about subcutaneous ocrelizumab.
- Main caveat: these are registry records, not published outcomes.

## Clinical research

For each important research/trial item, use this shape:

### <Plain title>

What it is: one sentence.
Why it matters: 1–3 sentences.
What we know so far: 1–3 bullets.
What we do not know yet: 1–2 bullets.
Evidence level: high | medium | low | registry-only.
KB: `kb/pages/<slug>.md`
Source: DOI/PMID/NCT/official URL in plain text.

## Better MS / practical living

Only include practical guidance from recognized MS organizations or official
sources. Keep it non-prescriptive. Use this shape:

### <Plain title>

Useful takeaway: 1–2 sentences.
Care caveat: one sentence.
KB/source: path or URL.

## Worth watching

2–6 short items that are credible but not ready for the main section. Say why:
needs PubMed verification, early trial only, news report not yet peer-reviewed,
conference item, etc.

## What to be careful about

A short caveat section in normal language: registry-only, small samples,
abstract-only, paywalled full text, preliminary signal, no outcome data, etc.

## KB footer

Small operational footer:

- Pages added/updated: <N>
- Queries answered: <N>
- Watch reports reviewed: <N>
- Full KB paths for relevant reports
```

## Output: Matrix message

Send a compact version to `$MATRIX_HOME_ROOM` that renders well in chat.
No emojis, no `[[wikilinks]]`, no markdown footnotes.

Use this exact style:

```markdown
This week in MS — Week <NN>

Short version:
- <one useful human-readable bullet>
- <one useful human-readable bullet>
- <one useful human-readable bullet>

Clinical research:
1. <Plain title>
   What it is: <one sentence>
   Why it matters: <one or two sentences>
   Caveat: <one sentence>
   KB: kb/pages/<slug>.md

2. <Plain title>
   What it is: ...
   Why it matters: ...
   Caveat: ...
   KB: kb/pages/<slug>.md

Better MS / practical living:
- <0–3 useful practical bullets; omit section if none this week>

Worth watching:
- <0–3 credible-but-not-ready items; say what verification is needed>

Bottom line:
<one calm sentence. Example: "Useful tracking week, not a practice-changing week." >

Full digest: kb/reports/<YYYY>_W<NN>.md
Logseq digest: https://ms-kb.dobryops.com/#/page/<URL-encoded report page title or slug>
Start Here: https://ms-kb.dobryops.com/#/page/Start%20Here
Browse whole KB: https://ms-kb.dobryops.com/kb/
```

Keep the Matrix message short enough to read quickly. If there are many items,
choose the best 3 and put the rest in the report file.

## After delivery

Refresh `$KB_ROOT/pages/Start Here.md` so the KB front door points at this new
weekly digest, highlights the best current pages, and includes `[Browse the
whole KB](/kb/)` for raw file-tree browsing. Keep this page reader-first: no
feed-count headlines, no operational backlog language, no Logseq wikilinks.
Never write `[[/kb/]]`; it is a broken Logseq page link, not a URL.

The Matrix message must also include three web links at the bottom:

- `Logseq digest: https://ms-kb.dobryops.com/#/page/<URL-encoded report page title or slug>`
- `Start Here: https://ms-kb.dobryops.com/#/page/Start%20Here`
- `Browse whole KB: https://ms-kb.dobryops.com/kb/`

If `LOGSEQ_BASE_URL` is set in the future, replace the hardcoded base with that
env value. Keep the links plain and clickable; do not wrap them in Logseq
wikilinks.

Call `kb-journal` with `event: digest written: <YYYY>_W<NN>`.

## Rules

- Cite-or-silent applies. A highlight must point to a KB page/report with
  sources, DOI/PMID/NCT/official URL, or it does not get highlighted.
- Do not present ClinicalTrials.gov registry entries as results.
- Do not write treatment recommendations. Use: "this is what was reported; a
  clinician interprets this for individual care."
- Be warm, calm, and practical. This is for people living with the disease,
  not for a lab meeting.
