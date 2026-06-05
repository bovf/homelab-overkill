import json
import os
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("turn-tracker")

_STATE_DIR = Path(
    os.environ.get(
        "KOTH_STATE_DIR",
        str(Path.home() / ".hermes" / "koth-state"),
    )
)
_STATE_FILE = _STATE_DIR / "combat.json"


def _load() -> dict:
    try:
        return json.loads(_STATE_FILE.read_text())
    except FileNotFoundError:
        return {"active": False, "order": [], "index": 0, "round": 0}


def _save(state: dict) -> None:
    _STATE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = _STATE_FILE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, indent=2))
    tmp.replace(_STATE_FILE)


@mcp.tool()
def init_combat(initiative_order: list[str]) -> dict:
    """Start combat with the given initiative order, pre-sorted highest-rolled first.

    Pass the player/NPC names in the order they will act, e.g.
    `["@bovf", "Mann Co. Goon A", "@papaimpy", "@napcraft"]`. Round counter
    starts at 1. The first name in the list is the active turn.
    """
    if not initiative_order:
        raise ValueError("initiative_order must be non-empty")
    state = {
        "active": True,
        "order": list(initiative_order),
        "index": 0,
        "round": 1,
    }
    _save(state)
    return {"current": state["order"][0], "round": 1, "order": state["order"]}


@mcp.tool()
def current_turn() -> dict:
    """Return whose turn it currently is. `active=False` when no combat is in progress.

    The GM MUST call this every time before announcing whose turn it is.
    NEVER state the turn order from memory.
    """
    state = _load()
    if not state.get("active"):
        return {"active": False}
    return {
        "active": True,
        "current": state["order"][state["index"]],
        "round": state["round"],
        "index": state["index"],
        "order": state["order"],
    }


@mcp.tool()
def advance_turn() -> dict:
    """Advance to the next combatant. Increments the round counter when wrapping."""
    state = _load()
    if not state.get("active"):
        raise ValueError("no active combat — call init_combat first")
    state["index"] += 1
    if state["index"] >= len(state["order"]):
        state["index"] = 0
        state["round"] += 1
    _save(state)
    return {
        "current": state["order"][state["index"]],
        "round": state["round"],
        "index": state["index"],
    }


@mcp.tool()
def add_combatant(name: str) -> dict:
    """Append a combatant to the end of the turn order (mid-combat reinforcements)."""
    state = _load()
    if not state.get("active"):
        raise ValueError("no active combat")
    if name in state["order"]:
        raise ValueError(f"{name!r} is already in the order")
    state["order"].append(name)
    _save(state)
    return {"order": state["order"]}


@mcp.tool()
def remove_combatant(name: str) -> dict:
    """Remove a combatant (dropped, fled, dead). Re-anchors the current-turn index."""
    state = _load()
    if not state.get("active"):
        raise ValueError("no active combat")
    if name not in state["order"]:
        raise ValueError(f"{name!r} is not in the order")
    removed_at = state["order"].index(name)
    state["order"].remove(name)
    if not state["order"]:
        state["active"] = False
        state["index"] = 0
    elif removed_at < state["index"]:
        state["index"] -= 1
    elif state["index"] >= len(state["order"]):
        state["index"] = 0
        state["round"] += 1
    _save(state)
    return {
        "active": state["active"],
        "order": state["order"],
        "current": state["order"][state["index"]] if state["active"] else None,
        "round": state["round"],
    }


@mcp.tool()
def end_combat() -> dict:
    """Clear combat state. Use when the encounter resolves."""
    _save({"active": False, "order": [], "index": 0, "round": 0})
    return {"active": False}


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
