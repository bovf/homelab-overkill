import json
import os
import re
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("character-sheets")

_STATE_DIR = Path(
    os.environ.get(
        "KOTH_STATE_DIR",
        str(Path.home() / ".hermes" / "koth-state"),
    )
)
_CHAR_DIR = _STATE_DIR / "characters"

_STAT_MIN = -1
_STAT_MAX = 3


def _safe_name(name: str) -> str:
    cleaned = re.sub(r"[^a-z0-9_-]", "", name.lower().replace(" ", "_"))
    if not cleaned:
        raise ValueError(f"name {name!r} has no safe filesystem characters")
    return cleaned


def _path(name: str) -> Path:
    return _CHAR_DIR / f"{_safe_name(name)}.json"


def _load(name: str) -> dict:
    p = _path(name)
    if not p.exists():
        raise ValueError(f"no character {name!r}")
    return json.loads(p.read_text())


def _save(sheet: dict) -> None:
    _CHAR_DIR.mkdir(parents=True, exist_ok=True)
    p = _path(sheet["name"])
    tmp = p.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(sheet, indent=2))
    tmp.replace(p)


def _validate_stat(label: str, value: int) -> int:
    if not isinstance(value, int):
        raise ValueError(f"{label} must be an integer, got {value!r}")
    if not (_STAT_MIN <= value <= _STAT_MAX):
        raise ValueError(
            f"{label} mod out of range: {value} (expected {_STAT_MIN}..{_STAT_MAX})"
        )
    return value


@mcp.tool()
def create_character(
    name: str,
    player: str,
    faction: str,
    concept: str,
    standout_trait: str,
    key_relationship: str,
    open_thread: str,
    brawn: int,
    cunning: int,
) -> dict:
    """Create a new PC sheet. Use only at session zero (or when a player joins mid-campaign) after the player approves the full sheet aloud.

    Args:
        name: PC's character name (NOT the player's mxid).
        player: player's matrix mxid, e.g. '@bovf:matrix.dobryops.com'.
        faction: which seed faction or workshopped variant.
        concept: 1-2 sentences on who they are.
        standout_trait: the one phrase that makes them them.
        key_relationship: NPC they're tied to (existing or new).
        open_thread: unresolved hook the GM can pull on.
        brawn: physical mod, -1 to +3 inclusive.
        cunning: mental/social mod, -1 to +3 inclusive.
    """
    _validate_stat("brawn", brawn)
    _validate_stat("cunning", cunning)
    if _path(name).exists():
        raise ValueError(
            f"{name!r} already exists — use update_character to modify"
        )
    sheet = {
        "name": name,
        "player": player,
        "faction": faction,
        "concept": concept,
        "standout_trait": standout_trait,
        "key_relationship": key_relationship,
        "open_thread": open_thread,
        "stats": {"brawn": brawn, "cunning": cunning},
        "conditions": [],
        "inventory": [],
    }
    _save(sheet)
    return sheet


@mcp.tool()
def get_character(name: str = "", player: str = "") -> dict:
    """Retrieve a PC by character name OR by player mxid. Pass exactly one.

    Use BEFORE rolling for a player: call get_character(player='@bovf:…'),
    read the stat block, then call dice_roller.roll('2d6+<stat>').
    """
    if name and player:
        raise ValueError("pass name OR player, not both")
    if name:
        return _load(name)
    if player:
        if not _CHAR_DIR.exists():
            raise ValueError(f"no character for player {player!r}")
        for f in sorted(_CHAR_DIR.glob("*.json")):
            sheet = json.loads(f.read_text())
            if sheet.get("player") == player:
                return sheet
        raise ValueError(f"no character for player {player!r}")
    raise ValueError("must pass name or player")


@mcp.tool()
def list_characters() -> list[dict]:
    """List every PC in the campaign with name, player mxid, faction, and stats."""
    if not _CHAR_DIR.exists():
        return []
    out = []
    for f in sorted(_CHAR_DIR.glob("*.json")):
        s = json.loads(f.read_text())
        out.append(
            {
                "name": s["name"],
                "player": s["player"],
                "faction": s["faction"],
                "stats": s["stats"],
            }
        )
    return out


@mcp.tool()
def update_character(name: str, field: str, value) -> dict:
    """Mutate a top-level field or a nested stat. Examples:
    - update_character('Bovf', 'open_thread', 'Found the relic shard')
    - update_character('Bovf', 'stats.brawn', 3)
    - update_character('Bovf', 'conditions', ['wounded', 'inspired'])

    Field paths support one level of nesting with `.` (e.g. 'stats.cunning').
    """
    sheet = _load(name)
    if "." in field:
        outer, inner = field.split(".", 1)
        if outer not in sheet or not isinstance(sheet[outer], dict):
            raise ValueError(f"no nested field {outer!r}")
        if outer == "stats":
            _validate_stat(inner, value)
        sheet[outer][inner] = value
    else:
        sheet[field] = value
    _save(sheet)
    return sheet


@mcp.tool()
def delete_character(name: str) -> dict:
    """Remove a PC sheet. Use only with explicit player consent (retirement, death-with-consent, scrapped concept)."""
    p = _path(name)
    if not p.exists():
        raise ValueError(f"no character {name!r}")
    p.unlink()
    return {"deleted": name}


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
