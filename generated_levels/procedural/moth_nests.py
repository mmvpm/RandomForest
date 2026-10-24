"""Validate optional, authored resident moth colonies independently of gameplay geometry."""

import math


def validate_moth_nests(level: dict) -> None:
    """Keep up to three stable, bounded visual anchors in actual air cells."""
    nests = level.get("moth_nests", [])
    if not isinstance(nests, list) or len(nests) > 3:
        raise ValueError("moth_nests must contain zero to three colonies")
    seen = set()
    for nest in nests:
        if not isinstance(nest, dict) or not isinstance(nest.get("id"), str) or not nest["id"] or nest["id"] in seen:
            raise ValueError("Each moth colony needs a unique nonempty id")
        seen.add(nest["id"])
        x, y = nest.get("x"), nest.get("y")
        if any(not isinstance(value, (int, float)) or not math.isfinite(value) for value in (x, y)):
            raise ValueError("Moth coordinates must be finite numbers")
        column, row = int(x // 12), int(y // 12)
        if not (0 <= x < level["width"] * 12 and 0 <= y < level["height"] * 12):
            raise ValueError("Moth anchor leaves the map")
        if level["map"][row][column] in "#X=^v<>UDLR":
            raise ValueError("Moth anchor must be in visible air")
        count, radius = nest.get("count", 30), nest.get("radius", 65)
        if not isinstance(count, int) or not 18 <= count <= 36:
            raise ValueError("Moth count must be an integer from 18 to 36")
        if not isinstance(radius, (int, float)) or not 36 <= radius <= 80:
            raise ValueError("Moth radius must be from 36 to 80 pixels")
