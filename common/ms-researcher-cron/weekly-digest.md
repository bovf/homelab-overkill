---
name: weekly-digest
description: Every Monday 08:00 (Europe/Sofia) — summarize the last 7 days of kb activity and deliver to the home Matrix room.
schedule: "0 8 * * MON"
timezone: "Europe/Sofia"
delivery:
  channel: matrix
  target: env:MATRIX_HOME_ROOM
---

# Weekly digest

It is Monday morning. Write the weekly knowledgebase digest for the last
seven calendar days and deliver it to the home Matrix room.

## Inputs you must read (in order)

1. `$KB_ROOT/journals/` — every file with `last-modified` within the last
   7 days. Each is a bulleted timeline.
2. `$KB_ROOT/pages/` — every file with `last-modified` within the last
   7 days. Read the frontmatter for `type`, `evidence_grade`, and
   `sources`.
3. `$KB_ROOT/queries/` — every file with `last-modified` within the last
   7 days. These are real questions the household asked.

If a week has zero activity, deliver a one-line digest:

> "📚 No new research this week."

Do not pad. Do not invent activity.

## Output: write the report file

Path: `$KB_ROOT/reports/<YYYY>_W<NN>.md`, where `NN` is the ISO week
number, two digits, zero-padded.

Template:

```markdown
---
type: report
period: "<YYYY>-W<NN>"
generated: <YYYY-MM-DD HH:MM:SS Europe/Sofia>
pages_touched: <integer>
queries_answered: <integer>
ingests: <integer>
---

# Week <NN> of <YYYY>

## What we added or updated

- [[<page-slug>]] — one-line plain-English description. `evidence_grade: <grade>`. <N> sources.
- ...

## What we were asked

- [[<query-slug>]] — the question, in one line.
- ...

## Three things worth reading

(Pick the three most consequential — strong evidence, household-relevant,
or a meaningful change in the field. State plainly why each made the cut.)

1. **[[<page-slug>]]** — one paragraph on why this matters this week.
2. **[[<page-slug>]]** — one paragraph.
3. **[[<page-slug>]]** — one paragraph.

## Caveats

(Anything from this week's pages with `evidence_grade: low` or where the
"Caveats" section flagged something serious. Surface it — don't bury it.)
```

## Output: the chat message

Deliver the report's markdown body to `$MATRIX_HOME_ROOM` (the home
channel — Dobry + GF). Lead with a single-line headline so it renders
sanely on mobile:

> "📚 Week <NN> digest — <pages_touched> pages, <queries_answered>
> queries answered. Top read this week: <one-line on #1>."

Then the full markdown body.

End with a single line pointing at the report path:

> "Full digest: `kb/reports/<YYYY>_W<NN>.md` (open in Logseq for the
> backlinks)."

## After delivery

Call `kb-journal` with `event: digest written: <YYYY>_W<NN>`.

## Rules

- **Cite-or-silent applies here too.** A "thing worth reading" must
  reference a page that itself has citations. Do not summarize content
  the kb doesn't have sources for.
- **Don't editorialize the field.** "BTK inhibitor news this week" is
  fine if a new page covers it. "BTK inhibitors are the future" is not.
- **Don't repeat last week.** If a page is unchanged from last week's
  digest, skip it.
- **Don't apologize for low activity.** A quiet week is a quiet week.
