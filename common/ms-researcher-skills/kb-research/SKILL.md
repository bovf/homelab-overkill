---
name: kb-research
description: Answer a research question by searching the kb first, then PubMed → CrossRef → SearXNG, writing a citation-grounded content page under $KB_ROOT/content/<type>/YYYY/MM/. Every claim cites a DOI/PMID/URL or is dropped. This is the heart of the agent.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [kb, research, citation, ms-research]
    category: ms-knowledgebase
    related_skills: [kb-ingest, kb-journal]
---

# kb-research

Answer a research question with a citation-grounded knowledgebase page.

## When to use

User asks any factual question about MS research, treatment, biomarkers,
clinical trials, drugs, mechanisms, etc. Examples:

- "what's the current status of BTK inhibitors for progressive MS?"
- "summarize what we know about ocrelizumab"
- "is there evidence that vitamin D affects relapse rate?"
- "what's the latest from clinicaltrials.gov on MS?"

## Env vars

- `$KB_ROOT` — kb tree root.

## The procedure (do this in order; do not skip)

### 1. Check the kb first

Search both canonical content and navigation pages:

```bash
grep -ril "<key-terms>" $KB_ROOT/content/ $KB_ROOT/pages/ 2>/dev/null
```

If a fresh content page exists (`last_reviewed` within the last 60 days), return
it. Don't re-research what you already have. Tell the user "we already have a
page on this from <date>; here it is."

### 2. PubMed first for medical claims

For any question about drugs, mechanisms, clinical findings, trials:
call `pubmed.pubmed_search(query, max_results=10)`. Read the titles +
abstracts. Pick the 3–5 most relevant.

For each picked PMID, call `pubmed.pubmed_fetch(pmid)` to get the
abstract, authors, journal, year, DOI, and MeSH terms.

### 3. Verify DOIs via CrossRef

For every DOI from step 2, call `crossref.crossref_lookup(doi)` to confirm
the citation metadata. **If CrossRef returns 404 or the title doesn't
match, drop the citation.** Do not invent corrections.

### 4. SearXNG as backup, not primary

If PubMed returns fewer than 3 usable results, call
`searxng.searxng_search(query, categories=['science'])`. If still thin,
try `categories=['general']`.

Triage SearXNG hits by domain:
- **Recognized peer-reviewed / official:** pubmed.ncbi.nlm.nih.gov,
  nejm.org, thelancet.com, msard-journal.com, n.neurology.org, jneurology,
  clinicaltrials.gov, nih.gov, ninds.nih.gov, who.int, nationalmssociety.org,
  msif.org → use as supporting citations.
- **Everything else** → may be cited ONLY with `evidence_grade: low`
  flag in the page frontmatter and an explicit body note: "this is from
  a non-peer-reviewed source — treat as preliminary."

### 5. Write the page

Path depends on type and date. Use Europe/Sofia current date unless the source
publication/trial date clearly provides a better date:

- study → `$KB_ROOT/content/studies/YYYY/MM/<slug>.md`
- trial → `$KB_ROOT/content/trials/YYYY/MM/<slug>.md`
- practical guidance → `$KB_ROOT/content/practical/YYYY/MM/<slug>.md`
- concept/drug overview → `$KB_ROOT/content/studies/YYYY/MM/<slug>.md` unless it is primarily practical guidance

Slug: lowercase ASCII, `_` separator, ≤60 chars. For studies, use
`study_<doi_slug>.md` (e.g. `study_10_1056_nejmoa1601277.md`). For trials, use
`trial_<nct>_<short_slug>.md`.

Use this template:

```markdown
---
type: study | drug | concept | person | trial
status: active
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
topics:
  - clinical-research
created: YYYY-MM-DD
canonical_path: content/<type>/YYYY/MM/<slug>.md
---

# <Page title>

One paragraph in plain English. No jargon without the expansion on first use.

## Key findings

- Finding 1 with citation [^1].
- Finding 2 with citation [^2] and a [[backlink_to_related_page]].
- ...

## Caveats / uncertainty

- Sample size: n=...
- Study design weaknesses (open-label, short follow-up, industry-funded, etc.).
- What this does NOT prove.

## See also

- [[related_page_1]]
- [[related_page_2]]

[^1]: First author et al. "Title." Journal Year. DOI: 10.xxxx/yyyy. PMID: 12345678.
[^2]: ...
```

**Rules for the body:**
- Every bullet under "Key findings" cites at least one source.
- A claim without a citation does not get written. Period.
- Add `[[backlinks]]` to any existing page (`grep -l` first to find them).
- The "Caveats" section is mandatory — it tells the human reader what to
  doubt.

### 6. Journal it

Call `kb-journal` with the event: `event: page <slug> (new|updated), n_sources=<N>`.

### 7. Reply to chat

```
📚 Wrote kb/content/<type>/YYYY/MM/<slug>.md (evidence_grade: <grade>, <N> sources).

<2–4 sentence plain-English summary>

Sources cited: <DOI 1>, <DOI 2>, <DOI 3>.
Caveats: <one line on the main caveat>.

Open in KB: kb/content/<type>/YYYY/MM/<slug>.md
```

## What you must NOT do

- **Don't invent citations.** If you can't verify a DOI via CrossRef, drop it.
- **Don't summarize from training data.** Every factual claim flows from a
  step-2-or-step-4 result.
- **Don't oversell.** A single trial is "preliminary." Two independent
  trials with consistent results is "evidence suggests." A meta-analysis
  of multiple trials is "strong evidence."
- **Don't write treatment recommendations.** Cite what the trials showed;
  let the user's clinician interpret.
- **Don't omit caveats.** Every page has a Caveats section, even if you
  have to write "no major caveats noted in the cited sources."
- **Don't paywall-cite blind.** If you couldn't read past the abstract,
  say so: "abstract only — full text behind paywall."

## When nothing comes back

If PubMed has zero matches and SearXNG returns only low-grade hits, write
the page anyway, but mark `status: unanswered` in frontmatter, and in the
body write: "Searched PubMed (`<query>`, 0 results) and SearXNG; no
peer-reviewed sources found. If you have a specific study in mind, ingest
it and I'll add it."

## Rules summary

1. Cite or stay silent.
2. PubMed > CrossRef-verified DOI > SearXNG.
3. Every page has Caveats.
4. Update `last_reviewed` if you touch a page.
5. Put new content in the V2 canonical `content/<type>/YYYY/MM/` layout, not
   the legacy flat `pages/` directory. `pages/` is for Start Here, Index, and
   sub-index navigation pages.
6. Journal every meaningful action.
7. Reference `$KB_ROOT` by name; never paste the value into chat.
