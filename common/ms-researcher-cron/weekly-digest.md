---
name: weekly-digest
description: Every Monday 08:00 (Europe/Sofia) — publish a readable MS field update for Dobry and GF, based on citation-grounded KB activity from the last week.
schedule: "0 8 * * MON"
timezone: "Europe/Sofia"
delivery:
  channel: matrix
  target: env:MATRIX_HOME_ROOM
---

# Monday MS field digest

It is Monday morning. Write a calm, useful, citation-grounded digest that
Dobry and his girlfriend can read together as a weekly tradition.

This is **not** an operations report. Do not lead with raw queue counts, feed
item totals, or internal processing mechanics. The goal is: "What changed in
the MS field this week, what is worth reading, and what should we treat with
caution?"

## Inputs you must read, in order

1. `$KB_ROOT/journals/` — files with `last-modified` in the last 7 days.
2. `$KB_ROOT/pages/` — files with `last-modified` in the last 7 days. Read
   frontmatter for `type`, `evidence_grade`, `sources`, and `last_reviewed`.
3. `$KB_ROOT/reports/` — last week's digest, if present, so you do not repeat
   unchanged items.
4. `$KB_ROOT/queries/rss_watch_*.md` from the last 7 days — use only for
   context on what was queued/rejected; do not present feed totals as news.
5. `$KB_ROOT/raw/rss/YYYY_MM_DD/*_candidates.md` from the last 7 days only
   for "watchlist / honourable mention" context. Do not cite raw RSS as
   evidence unless it points to an official source/DOI/PMID/NCT.

If a week has zero meaningful activity, deliver exactly:

> "📚 No new MS research highlights this week. The KB is quiet; we'll keep watching."

Do not pad. Do not invent activity.

## Selection rules

Pick items that are household-useful, field-relevant, or clinically meaningful.
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

Use this readable template:

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

# MS field notes — Week <NN> of <YYYY>

## At a glance

A 3–5 bullet executive summary in plain language. Each bullet must point to a
KB page/report with sources. No internal queue statistics here.

## Top highlights

Pick 3–5. For each:

### <Plain-language title>

- **Why it matters:** 2–4 sentences for a human reader living with MS.
- **What changed this week:** one concrete change from the KB/source.
- **Evidence level:** high | medium | low | registry-only.
- **Caveat:** the main limitation.
- **Read in KB:** `kb/pages/<slug>.md`

## Clinical trial watch

Short bullets for new/recruiting/changed trials that matter. Make clear when
an item is registry-only and has no outcome data yet.

## Practical living / care navigation

Only include practical tips from recognized MS organizations or official
sources. Do not give individualized medical advice.

## Honourable mentions / watchlist

2–6 short bullets for credible queued items, conference/news leads, or early
signals that are worth watching but not yet strong enough for a top highlight.
Say what verification is still needed.

## Caveats this week

Plain-language uncertainty: small samples, registry-only, abstract-only,
paywalled full text, preliminary signal, news not yet peer-reviewed, etc.

## KB changes

Small operational footer, not the headline:

- Pages added/updated: <N>
- Queries answered: <N>
- RSS/watch reports reviewed: <N>
- Cleanup/report paths if relevant
```

## Output: Matrix message

Send a warm compact version to `$MATRIX_HOME_ROOM`.

Start with:

> "📚 Monday MS field notes — Week <NN>: <one-sentence human headline>."

Then include:

- `Top 3 this week` — three short bullets.
- `Trial watch` — 0–3 bullets.
- `Practical / living with MS` — 0–3 bullets.
- `Honourable mentions` — 0–3 bullets.
- `Main caveat` — one sentence.
- `Full digest: kb/reports/<YYYY>_W<NN>.md`

Keep the Matrix message readable on mobile. Do not paste a giant markdown file
unless the week is genuinely dense. The report file can be longer.

## After delivery

Call `kb-journal` with `event: digest written: <YYYY>_W<NN>`.

## Rules

- Cite-or-silent applies. A highlight must point to a KB page/report with
  sources, DOI/PMID/NCT/official URL, or it does not get highlighted.
- Do not present ClinicalTrials.gov registry entries as results.
- Do not write treatment recommendations. Use: "this is what was reported; a
  clinician interprets this for individual care."
- Be warm, calm, and practical. This is for people living with the disease,
  not for a lab meeting.
