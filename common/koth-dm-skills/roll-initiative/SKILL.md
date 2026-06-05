---
name: roll-initiative
description: Start a combat encounter by rolling initiative for all combatants and registering the sorted order with the turn-tracker MCP. From this point forward, current_turn() is the single source of truth — turn order is NEVER stated from LLM memory.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [koth-dm, combat, dice, turn-order, initiative]
    category: campaign-management
    related_skills: [koth-dm-journal]
    config:
      destructive: false
---

# roll-initiative

Open a combat encounter cleanly. After this skill runs, every turn-order
question goes through the `turn-tracker` MCP tool — no memory-based turn
announcements, no skipped players, no drift.

## When to invoke

The GM (you) decides combat is starting. Typical triggers from the table:

- A player declares an attack against an active NPC threat
- An ambush, surprise round, or contested arrival breaks freeform play
- The GM has set up an encounter and announces "roll initiative"

If only one player is involved (a 1-on-1 NPC interaction), you may skip this
skill and just resolve with dice rolls — the turn-tracker is for actual
multi-combatant scenes.

## Procedure

1. **Collect combatants.** Names of every PC who's present and every NPC who
   will act in the encounter. Players go by their matrix display name
   (e.g. `@bovf`). NPCs go by their canonical name from `CAMPAIGN.md` /
   `CAMPAIGN_JOURNAL.md` — if you haven't named them yet, name them now and
   log them later.

2. **Roll initiative for each.** This campaign treats initiative as a
   Cunning check (no separate DEX stat — Cunning covers reflexes and read
   of the room). For each PC:

   - Call `character_sheets.get_character(player='<their mxid>')` to fetch
     the sheet.
   - Compose `f"1d20+{cunning}"` from `stats.cunning`.
   - Call `dice_roller.roll(expr)` and record the total against the PC's
     name.

   For each NPC, call `dice_roller.roll("1d20+<NPC mod>")` directly — NPCs
   don't have sheets in v1; you assign mods on the fly based on what feels
   right for the encounter (typical goon: +0, elite: +2, boss: +3).

   If a player explicitly wants to roll their own initiative (matter of
   table preference), accept their reported number and skip the
   character-sheets lookup for that one PC. Tie-breaks: PC beats NPC.

3. **Sort the order.** Build the list of names from highest-rolled to
   lowest-rolled. This is your initiative order.

4. **Register with turn-tracker.** Call the `turn-tracker` MCP tool:
   `init_combat(initiative_order=[<sorted names>])`. The tool returns the
   first combatant — that's whose turn it is in round 1.

5. **Announce.** Open the round in voice and call the first turn:

   > "🎲 Initiative — round 1. Order: <list>. Turn: `@<first>` — describe
   > your action."

## After init_combat

From here on, you are bound to these rules:

- **Before EVERY message** during combat, call `turn_tracker.current_turn()`.
  Use its return value as the authoritative active combatant.
- **NEVER** state whose turn it is from memory. If the MCP says
  `current=@papaimpy`, that's who's up, even if you "remember" otherwise.
- **When the active player resolves their action**, call
  `turn_tracker.advance_turn()` to roll forward. The tool will bump the
  round counter when it wraps.
- **If a combatant joins mid-fight**, call
  `turn_tracker.add_combatant(name=...)` — they slot in at the end of the
  current round's order.
- **If a combatant drops** (fled, dead, unconscious), call
  `turn_tracker.remove_combatant(name=...)`.
- **When the encounter resolves** (one side flees, all enemies down, parley
  succeeds), call `turn_tracker.end_combat()` and return to freeform mode.

## Why this matters

LLM-driven GMs are notoriously bad at turn order — they skip players,
re-announce the same turn, hallucinate that a player has acted twice, or
drop NPCs from the order silently. The turn-tracker MCP is the source of
truth that prevents all of that. The cost is one tool call per message
during combat. Pay it.

Related: `koth-dm-journal` logs encounter outcomes at session end.
