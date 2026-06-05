import random
import re

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("dice-roller")

_DIE_RE = re.compile(
    r"^(?P<n>\d*)d(?P<s>\d+)(?:k(?P<kk>[hl])(?P<kn>\d+))?$",
    re.IGNORECASE,
)
_INT_RE = re.compile(r"^\d+$")


def _roll_term(term: str) -> tuple[int, str]:
    if _INT_RE.match(term):
        v = int(term)
        return v, str(v)
    m = _DIE_RE.match(term)
    if not m:
        raise ValueError(f"unparseable term {term!r}")
    n = int(m.group("n") or "1")
    s = int(m.group("s"))
    if not (1 <= n <= 1000):
        raise ValueError(f"dice count out of range: {n}")
    if not (2 <= s <= 1000):
        raise ValueError(f"die size out of range: {s}")
    rolls = [random.randint(1, s) for _ in range(n)]
    kk = m.group("kk")
    if kk:
        kn = int(m.group("kn"))
        if not (1 <= kn <= n):
            raise ValueError(f"keep count out of range: keep {kn} of {n}")
        kept = sorted(rolls, reverse=(kk.lower() == "h"))[:kn]
        subtotal = sum(kept)
        return subtotal, f"{n}d{s}k{kk}{kn}={rolls}→kept{kept}={subtotal}"
    return sum(rolls), f"{n}d{s}={rolls}={sum(rolls)}"


@mcp.tool()
def roll(expr: str) -> dict:
    """Evaluate a dice expression and return total + breakdown.

    Supports addition/subtraction of integer modifiers and dice terms:
      `1d20+5`, `2d6+3`, `4d6kh3` (keep highest 3 — D&D ability score),
      `2d20kh1` (advantage), `2d20kl1` (disadvantage), `1d100-10`.

    Always use this tool for any roll the GM needs to make for NPCs, the
    world, or for resolution math. NEVER compute dice results from memory —
    LLM dice math drifts toward middle-of-range outcomes.
    """
    cleaned = expr.replace(" ", "")
    if not cleaned:
        raise ValueError("empty expression")
    parts = re.findall(r"[+-]?[^+-]+", cleaned)
    total = 0
    pieces: list[str] = []
    for raw in parts:
        sign = 1
        term = raw
        if term.startswith("+"):
            term = term[1:]
        elif term.startswith("-"):
            sign = -1
            term = term[1:]
        sub, br = _roll_term(term)
        total += sign * sub
        prefix = "-" if sign < 0 else ("+" if pieces else "")
        pieces.append(f"{prefix}{br}")
    return {"expression": expr, "total": total, "breakdown": "".join(pieces)}


def main() -> None:
    mcp.run()


if __name__ == "__main__":
    main()
