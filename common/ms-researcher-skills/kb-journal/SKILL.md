---
name: kb-journal
description: Append a single timestamped bullet to today's $KB_ROOT/journals/YYYY_MM_DD.md describing what the agent just did. Logseq journal-compatible. Call this at the end of every meaningful action (page write, ingest, query answered).
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [kb, journal, logseq, ms-research]
    category: ms-knowledgebase
    related_skills: [kb-ingest, kb-research]
---

# kb-journal

Write one bullet to today's daily journal. The weekly digest reads these.

## When to use

Call this **at the end of every meaningful action**:
- After `kb-ingest` saves something to raw/.
- After `kb-research` writes/updates a page.
- After a Q&A worth preserving (also save the transcript to `kb/queries/`).
- After any change a future-you would want to see in last-7-days context.

Do NOT call it for tiny mechanical actions like "user said hi."

## Env vars

- `$KB_ROOT` — kb tree root.

## How

1. Compute today's date in `YYYY_MM_DD` format (Europe/Sofia timezone).
2. Compute `HH:MM` (Europe/Sofia).
3. File path: `$KB_ROOT/journals/<date>.md`. Create it if missing with a
   first line `# <date>` heading (Logseq treats the filename as the date
   already, but the H1 helps for git diffs).
4. Append one bullet on a new line:

   ```markdown
   - **HH:MM** — <event description, ≤120 chars>. Refs: [[<page>]] [[<page>]]
   ```

5. Use Logseq `[[wikilinks]]` for any page or query the event references.

## Event vocabulary

Pick the closest match:
- `ingested <slug>` — raw artifact saved.
- `page <slug> (new|updated), N=<sources>` — research page created/updated.
- `query <slug>` — Q&A session saved to `kb/queries/`.
- `digest written: <report-slug>` — weekly digest produced.
- `reviewed <slug>` — page touched, `last_reviewed` bumped, no body change.
- `flagged <slug>: low evidence` — low-evidence page written / re-flagged.

## Examples

```markdown
- **14:32** — page [[ocrelizumab]] (new, N=4). Refs: [[study_10_1056_nejmoa1601277]] [[anti_cd20_class]]
- **15:01** — ingested raw/2026_06_03_nejm_btk_inhibitor.pdf. Refs: [[btk_inhibitors]]
- **15:18** — query [[2026_06_03_btk_vs_anti_cd20]]. Refs: [[ocrelizumab]] [[evobrutinib]]
- **08:00** — digest written: [[2026_W22]].
```

## Output format for the user

Single line:

```
📓 journal: <date> — <event>
```

Don't echo the full journal back. If the user wants to read it, they open Logseq.

## Rules

- One bullet per call. Don't batch — the timestamp matters.
- Don't rewrite existing bullets. Append-only.
- Reference `$KB_ROOT` by name; never paste the value into chat.
- If the journal file doesn't exist yet today, create it with the H1
  heading first.
