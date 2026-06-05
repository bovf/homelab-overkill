# MS Researcher Knowledgebase

Citation-grounded notes about Multiple Sclerosis research, maintained by
the `ms-researcher` hermes-agent on engineer. Logseq-browseable.

## How to browse

Open this directory as a Logseq graph:

```
File → Open graph → /var/lib/ms-researcher/kb
```

(Or `~/kb` if you're sshed in as `ms-researcher`.)

Logseq treats `journals/` as the daily timeline, `pages/` as the node
graph, and `[[wikilinks]]` between them as edges. No setup needed.

## Tree

```
kb/
├── journals/   # daily agent activity, one file per day (YYYY_MM_DD.md)
├── pages/      # one node per topic, study, drug, biomarker, person
├── raw/        # raw ingested artifacts (PDFs, scraped text, .json sidecars)
├── queries/    # one-off Q&A sessions worth preserving
└── reports/    # weekly digests delivered to chat (YYYY_WNN.md)
```

## The rules

1. **Cite or stay silent.** Every claim in `pages/` has a DOI, PMID, or URL.
2. **Caveats are mandatory.** Every page lists what the study does NOT prove.
3. **Skepticism by default.** Single-study findings are "preliminary."
4. **Not a doctor.** This aggregates evidence. Clinicians interpret it.

## Weekly digest

A digest lands every Monday 08:00 (Europe/Sofia) in the shared Matrix
room. It summarizes the last 7 days of new/updated pages and points at
the 3 most worth-reading items.

## Page frontmatter (canonical)

```yaml
type: study | drug | concept | person | trial
status: active | superseded | outdated | unanswered
last_reviewed: YYYY-MM-DD
evidence_grade: high | medium | low
sources:
  - title: "..."
    doi: "10.xxxx/yyyy"
    pmid: "12345678"
    url: "https://..."
    journal: "..."
    year: 2024
    accessed: YYYY-MM-DD
```
