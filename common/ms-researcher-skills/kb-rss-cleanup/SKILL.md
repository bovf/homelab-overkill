---
name: kb-rss-cleanup
description: Safely prune generated RSS watcher raw cache after weekly digest retention, without touching manual raw ingests or the RSS seen ledger.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [kb, rss, cleanup, retention, ms-research]
    category: ms-knowledgebase
    related_skills: [kb-rss-watch, kb-journal]
---

# kb-rss-cleanup

Safely delete old generated RSS watcher raw cache. This skill must be boring,
conservative, and auditable.

## When to use

- Scheduled by `rss-raw-cleanup` every Monday at 10:00 Europe/Sofia.
- Run manually if the RSS raw cache grows too large.

## Retention policy

- Scope: **only** `$KB_ROOT/raw/rss/YYYY_MM_DD/` directories.
- Retention: delete date directories older than **14 days**.
- Never touch:
  - `$KB_ROOT/raw/` outside `raw/rss/`
  - `$KB_ROOT/raw/rss/seen_urls.txt`
  - non-date files or directories under `raw/rss/`
  - manual/user ingests, PDFs, pasted notes, DOI/PMID sidecars outside RSS cache
- Reasoning: weekly digest runs Monday 08:00. Cleanup runs Monday 10:00, after
  the digest has a chance to read the last week. Fourteen days keeps the just
  digested week plus a grace week for delayed runs.

## Required safe implementation

Use this exact Python-stdlib pattern or an equivalent with the same guards.
Do **not** use broad `rm -rf` globs.

```bash
python3 - <<'PY'
import datetime as dt
import re
import shutil
from pathlib import Path
from zoneinfo import ZoneInfo

kb = Path(__import__('os').environ['KB_ROOT']).resolve()
rss = (kb / 'raw' / 'rss').resolve()
assert str(rss).startswith(str(kb / 'raw')), f"refusing unsafe rss path: {rss}"

now = dt.datetime.now(ZoneInfo('Europe/Sofia'))
today = now.date()
cutoff = today - dt.timedelta(days=14)
pattern = re.compile(r'^\d{4}_\d{2}_\d{2}$')

deleted = []
kept = []
skipped = []
bytes_deleted = 0

if not rss.exists():
    rss.mkdir(parents=True, exist_ok=True)

for child in sorted(rss.iterdir()):
    if child.name == 'seen_urls.txt':
        skipped.append((child.name, 'seen ledger'))
        continue
    if not child.is_dir():
        skipped.append((child.name, 'not a directory'))
        continue
    if not pattern.match(child.name):
        skipped.append((child.name, 'not YYYY_MM_DD'))
        continue
    try:
        d = dt.datetime.strptime(child.name, '%Y_%m_%d').date()
    except ValueError:
        skipped.append((child.name, 'invalid date'))
        continue
    if d >= cutoff:
        kept.append(child.name)
        continue
    size = sum(p.stat().st_size for p in child.rglob('*') if p.is_file())
    shutil.rmtree(child)
    deleted.append(child.name)
    bytes_deleted += size

report_dir = kb / 'queries'
report_dir.mkdir(parents=True, exist_ok=True)
stamp = now.strftime('%Y_%m_%d_%H%M')
report = report_dir / f'rss_raw_cleanup_{stamp}.md'
report.write_text(
    '---\n'
    'type: query\n'
    'source: rss-raw-cleanup\n'
    f'generated: {now.strftime("%Y-%m-%d %H:%M Europe/Sofia")}\n'
    f'retention_days: 14\n'
    f'deleted_dirs: {len(deleted)}\n'
    f'bytes_deleted: {bytes_deleted}\n'
    '---\n\n'
    f'# RSS raw cleanup {now.strftime("%Y-%m-%d %H:%M")}\n\n'
    f'Cutoff: delete `$KB_ROOT/raw/rss/YYYY_MM_DD/` directories older than {cutoff.isoformat()}.\n\n'
    '## Deleted\n'
    + ''.join(f'- `{name}`\n' for name in deleted) + ('' if deleted else '- none\n')
    + '\n## Kept within retention\n'
    + ''.join(f'- `{name}`\n' for name in kept) + ('' if kept else '- none\n')
    + '\n## Skipped / protected\n'
    + ''.join(f'- `{name}` — {why}\n' for name, why in skipped) + ('' if skipped else '- none\n')
)
print(f'RSS cleanup report: {report}')
print(f'deleted_dirs={len(deleted)} bytes_deleted={bytes_deleted}')
PY
```

## After cleanup

Call `kb-journal` with:

`event: rss-cleanup deleted=<N>, bytes=<N>`

Reference the cleanup report in the journal when possible:

`Refs: [[rss_raw_cleanup_YYYY_MM_DD_HHMM]]`

## Rules

- If `$KB_ROOT` is missing or unsafe, stop and report the error.
- If Python errors, do not retry with shell globs.
- Never delete `seen_urls.txt`; it prevents duplicate feed processing.
- Never delete `raw/` top-level files.
- Never delete generated RSS raw data newer than 14 days.
