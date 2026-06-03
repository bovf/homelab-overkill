---
name: dice-check
description: Resolve any check, save, attack, or world-roll using the dice-roller MCP — never compute dice results from LLM memory.
version: 0.1.0
author: dobry-ops
license: MIT
metadata:
  hermes:
    tags: [koth-dm, dice, resolution]
    category: campaign-management
    related_skills: [roll-initiative, koth-dm-journal]
    config:
      destructive: false
---

# dice-check

Use the `dice-roller` MCP for every roll the GM (you) needs to make. Players
roll their own dice and report results. The GM rolls for: NPCs, the world,
weather, random tables, and anything else the players don't roll for.

## Hard rule

**Never compute a dice result from memory.** LLM dice math drifts toward
middle-of-the-range averages — random feeling is preserved but actual
randomness is not. Every roll goes through `dice_roller.roll(expr)`.

## Expression cheatsheet

| Expression | Meaning |
|---|---|
| `1d20+5` | One d20 plus modifier 5 (standard check / save / attack) |
| `2d6+3` | PbtA-style 2d6 + modifier (the campaign's hard-rule mechanic) |
| `4d6kh3` | 4d6, keep highest 3 (D&D 5e ability score generation) |
| `2d20kh1` | 2d20 keep highest (advantage) |
| `2d20kl1` | 2d20 keep lowest (disadvantage) |
| `1d100` | Percentile roll for random tables |
| `1d6-1` | One d6 minus 1 (e.g., poison damage with a negative mod) |

Combine freely: `2d6+1d4+3`, etc.

## When the GM rolls

- **NPC attacks / saves / checks** — roll them, report the breakdown if it
  matters to the fiction ("the goon's blade misses by 2 — the parry is *just*
  in time").
- **Random world events** — the storm intensifies? Roll for it. Hostage
  morale? Roll. The cap-point ticks? Roll.
- **PbtA resolution** — when a player's action calls for the 2d6+mod hard
  rule from `CAMPAIGN.md`, ASK the player to roll `2d6+<their_mod>`. You do
  NOT roll for them. The result they report drives the resolution: 10+
  clean, 7–9 mixed, 6– complication.

## What players roll

When a player needs to roll, ASK in plain English with the expression:

> "Bovf, roll `2d6+Brawn`."
> "Miro, that's a Cunning check — `2d6+Cunning`."
> "Kris, you've got disadvantage from the wound — `2d20kl1+Brawn`."

Then wait for them to report the number. Do NOT roll on their behalf.

## Reporting GM rolls

When YOU roll, include the expression and the result so the table can audit:

> "The goon swings — `1d20+4` → 17. Hit. Damage `1d8+2` → 6."

This keeps the roll honest and visible, even though the actual randomness
comes from the MCP.

Related: `roll-initiative` opens combat; `koth-dm-journal` logs outcomes.
