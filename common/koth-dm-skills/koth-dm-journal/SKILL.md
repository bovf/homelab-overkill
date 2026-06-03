---
name: koth-dm-journal
description: Append a session summary to ~/.hermes/CAMPAIGN_JOURNAL.md at session end (or on the user's explicit /journal request). Records session number, date, attendees, key events, decisions, open threads, and NPCs introduced — so the next session starts with continuity intact.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [campaign, journaling, continuity, koth-dm]
    category: campaign-management
    related_skills: []
    config:
      destructive: false
---

# koth-dm-journal

Append-only session summary to `~/.hermes/CAMPAIGN_JOURNAL.md`. This is how
the campaign remembers itself between sessions.

## When to invoke

- The table calls the session ("alright, let's call it"), OR
- A player explicitly types `/journal`, `wrap session`, `log session`, or
  equivalent unambiguous session-end language.

If you are uncertain whether the session is actually ending, **ASK**:

> "Wrapping the session — want me to log the journal entry now?"

Do NOT silently journal mid-session. Do NOT journal when only one player
says goodbye and the others are still active.

## What the entry must contain

Append a new section to `~/.hermes/CAMPAIGN_JOURNAL.md` using exactly this
shape:

```markdown
## Session <N> — <YYYY-MM-DD>

**Present**: <list of player mxids who participated>

### Recap
<2–4 sentence prose summary of what happened, in story voice. Lead with the
most important plot beat.>

### Key events
- <terse bullets, one per beat. Include: scenes entered, conflicts joined,
  outcomes, items gained/lost, alliances made/broken.>

### Decisions made
- <player-level commitments that bind future sessions. "Bovf swore the
  Wind-Walker oath." "The Order received the relic shard." etc.>

### NPCs introduced / advanced
- **<Name>** (<faction>) — <one-line description, key trait, current status>

### Open threads
- <unresolved hooks that future sessions can pull on. State them as questions
  or commitments. "What happens when the Order learns of the shard?">

### Hill control at session end
<which faction (if any) holds the summit, and how stable that hold is.>
```

Number sessions sequentially. If the journal is empty, this is Session 1.
Otherwise, read the last session number and add 1. Use the current date in
`YYYY-MM-DD` format (Sofia, Europe/Sofia timezone if it matters at a
day-boundary).

## Continuity rules

- **Never rename an NPC** introduced in a prior session. Read existing
  entries first to find the canonical name.
- **Never contradict** a "Decisions made" or "Hill control" entry from a
  prior session without acknowledging the retcon in the new entry.
- **Always log named NPCs** introduced this session — even minor ones — so
  next session they keep their names.

## Before invoking

1. Read existing `~/.hermes/CAMPAIGN_JOURNAL.md` (if it exists) to find the
   last session number and to surface any open threads being resolved this
   session.
2. Read `~/.hermes/CAMPAIGN.md` to confirm faction/world canon.
3. Draft the entry. Confirm session number, attendees, and Hill control with
   the players if any are ambiguous.
4. Append (do not overwrite) the new section.
5. Announce in the room: "📓 Session N logged. See you next time."

## After invoking

Do not continue the campaign in the same message. The session is over. If
players linger with table talk, respond out-of-character briefly and let the
room go quiet.
