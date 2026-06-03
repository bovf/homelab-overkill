---
name: start-campaign
description: Run a session zero — co-author the campaign's specifics with the three players (factions, PCs, the Hill's nature, opening scene). Cements decisions as canon by writing them to the campaign journal as Session 0. Use exactly once per campaign — at the very beginning, before any real play.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [koth-dm, session-zero, onboarding, world-building]
    category: campaign-management
    related_skills: [koth-dm-journal, roll-initiative, dice-check]
    config:
      destructive: false
---

# start-campaign

Drive a session-zero workshop with the three players (Dobry / `@bovf`, Kris /
`@papaimpy`, Miro / `@napcraft`). The goal is to convert `CAMPAIGN.md`'s
starter draft into binding canon — factions chosen, PCs created, the Hill's
specific nature decided, opening scene set — and to lock all of it into the
campaign journal as the Session 0 entry.

## When to invoke

Only ever **once per campaign**, when one of these is true:

- `~/.hermes/CAMPAIGN_JOURNAL.md` does not exist or contains no Session
  entries — i.e. no session has been played yet.
- A player explicitly asks: "start the campaign", "session zero", "let's
  begin", "let's set this up", or equivalent unambiguous setup language.

If the journal already has a Session 1 entry or later, **do NOT invoke**.
Decline and redirect — the campaign has already begun. If the user really
wants to reset, that's a manual op (clearing the journal), not this skill's
job.

## Hard prerequisite

Before stepping the players through this, **read `~/.hermes/CAMPAIGN.md` in
full**. You will reference its premise, factions, hard rules, and starter
NPCs throughout. Treat its content as the seed — players can refine, but
the bones (the Hill, the KotH twist, the three-faction shape, the hard
rules) are load-bearing.

## Procedure

### 1. Open with theatre, then drop into ops

A short bombastic premise recap to set tone (2–4 sentences). Mann Co.
flavour, the Hill looming, the three factions circling. Then **break the
fourth wall briefly** and say: "Right — before we open scene, I need
agreements from each of you. Five questions. Going around."

### 2. Faction choice (each player, in turn)

For each of the three players, present the three seed factions from
`CAMPAIGN.md`:

- **Mann Co. Industrial** — extract & monetize the Hill
- **The Order of the Standing Hour** — study & preserve
- **The Wind-Walker Clan** — claim & defend

ASK each player: "Which faction calls to you? Pick one of the three, OR
pitch a fourth — I'll workshop it with you live." Take their answer.
Encourage one-line riffs that personalize the faction (e.g. Mann Co. but
specifically the orphaned-blast-tech division; the Order specifically of
the lower-archive monks who broke vows). Get table consent on any
fourth-faction pitches — does it threaten the KotH dynamic? If yes,
re-pitch. If no, accept.

### 3. PC creation (each player, in turn)

For each player, ask in this order:

1. **Concept** — one or two sentences. Who are they within their faction?
   Veteran, defector, foundling, true believer, mercenary?
2. **Standout trait** — one phrase. The thing that makes them *them*.
3. **Key relationship** — one NPC (existing or new) they're tied to. If
   new, name + one-line who-are-they. Log them for the journal.
4. **Open thread** — one unresolved hook from before play started. A debt,
   a missing person, a stolen artifact, a vow. This is the GM's hook into
   their character's plotline.
5. **Stat mods** — keep it light. Two attributes: **Brawn** (physical),
   **Cunning** (mental/social). Each ranges from **-1 to +3**. Players
   assign +2 to one and +1 to the other; -1 is optional flavour. (For
   advantage/disadvantage situations or initiative, default DEX-style
   `+0` unless a player argues otherwise.)

Confirm each PC summary aloud before moving on. Players can edit until
they're happy.

### 4. The Hill — pick its nature

`CAMPAIGN.md` lists the Hill's summit as holding "a thing of ultimate
power — TBD". Present the seed options and ask the **table** (not
individuals) to pick:

- **A relic** (e.g. a war-engine fragment, a Mann Co. prototype that nobody
  was supposed to find)
- **A throne** (a ruler-binding seat — sit and you gain dominion, but)
- **A cap-point network** (multiple nodes, holding requires holding several)
- **An engine of old war** (literal Mann Co. doomsday weapon, half-buried)
- **Player pitch** (table proposes a fifth)

Get table consensus. Brief sensory detail of the chosen option (1–2
sentences) so it lives in everyone's head the same way.

### 5. Two named NPCs to anchor the world

The starter CAMPAIGN.md has TBD slots for one NPC per faction. ASK the
table: "I need three names. One Mann Co. forward-ops manager, one Standing
Hour archivist on the Hill, one Wind-Walker clan-second. Suggestions?"
Take their suggestions, propose a one-line trait + current status for
each. Confirm. These become canon.

### 6. Opening scene

CAMPAIGN.md has a placeholder opening scene (storm over the Hill, summit
just changed hands). Confirm or revise with the table. If they want a
different opening, accept their proposal — but cap it: one scene, opens
the campaign, ends on a choice point that demands action.

### 7. Lock canon — invoke koth-dm-journal

When all six steps resolve, **invoke `koth-dm-journal`** with a
specially-shaped entry titled "Session 0 — Session Zero":

```markdown
## Session 0 — Session Zero — <YYYY-MM-DD>

**Present**: @bovf, @papaimpy, @napcraft

### Canon decisions

#### Factions chosen
- **@bovf**: <faction + personalization>
- **@papaimpy**: <faction + personalization>
- **@napcraft**: <faction + personalization>

#### Player characters
- **@bovf**: <PC name>, <faction>. Concept: …. Trait: …. Brawn +N, Cunning +N.
- **@papaimpy**: …
- **@napcraft**: …

#### The Hill
The summit holds: <chosen option>. <1-sentence sensory>.

#### Anchor NPCs
- **<name>** (Mann Co.) — forward-ops manager. <trait>. <status>.
- **<name>** (Standing Hour) — archivist on the Hill. <trait>. <status>.
- **<name>** (Wind-Walker) — clan-second. <trait>. <status>.

#### Opening scene (agreed)
<one paragraph>

#### Hard rules (from CAMPAIGN.md, reaffirmed)
- No death without player consent.
- 2d6 + Brawn/Cunning resolves major decisions (10+ clean / 7-9 mixed / 6- complication).
- The Hill cannot be permanently controlled until the climax.

### Open threads (each PC's hook)
- **@bovf**: <thread>
- **@papaimpy**: <thread>
- **@napcraft**: <thread>

### Hill control at session end
Unsettled — opening situation in flux.
```

### 8. Hand off

After the journal lands, announce in the room:

> "📓 Session 0 logged. Canon is set. When you're ready, we open the
> scene — say `start scene` and we'll go."

Then **stop**. Do not start play in the same message. Session 1's
opening is its own moment — let them set the table for it.

## Hard rules for this skill

- **No dice.** Session zero is consent + canon. No initiative, no checks,
  no rolls. The first roll happens in Session 1.
- **One faction per player.** Even if two players want the same faction,
  push them apart — different sub-divisions, rival cells, fractured-from-
  the-same-order. The three-faction shape is load-bearing for the KotH
  dynamic.
- **Player consent gates canon.** If anyone at the table is uncertain
  about a decision, pause and renegotiate. Better to spend an extra hour
  in session zero than to retcon in session 5.
- **Do not improvise outside the seed.** The Hill, the three-faction
  shape, the KotH twist, and the hard rules are from CAMPAIGN.md and stay.
  Everything else is for the table to decide.
- **You only ever do this once.** If the journal already has a Session 1+
  entry, refuse and redirect.
