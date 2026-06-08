---
name: rss-raw-cleanup
description: Every Monday 10:00 (Europe/Sofia) — after the weekly digest, prune generated RSS watcher raw cache older than 14 days.
schedule: "0 10 * * MON"
timezone: "Europe/Sofia"
skills:
  - kb-rss-cleanup
  - kb-journal
---

# RSS raw cache cleanup

Run `kb-rss-cleanup` now.

Policy for this scheduled run:

- Delete only generated RSS cache directories under `$KB_ROOT/raw/rss/YYYY/MM/DD/` older than 14 days. Legacy `$KB_ROOT/raw/rss/YYYY_MM_DD/` directories may also be cleaned with the same safeguards during migration.
- Preserve the current week and previous week so the Monday 08:00 digest can
  source/cite/process recent RSS raw data before cleanup runs.
- Never touch manual raw ingests in `$KB_ROOT/raw/`.
- Never delete `$KB_ROOT/raw/rss/seen_urls.txt`.
- Write a cleanup report under `$KB_ROOT/content/queries/YYYY/MM/rss_raw_cleanup_YYYY_MM_DD_HHMM.md`.
- Append one `kb-journal` entry with deleted directory and byte counts.

If the cleanup report shows zero deletions, that is fine. Do not post to
Matrix unless there is an error or unsafe path refusal.
