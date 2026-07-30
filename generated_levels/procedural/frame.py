"""Add and inspect the fixed non-playable frame around generated maps."""

from __future__ import annotations


def _pad_rows(rows: list[str], padding: int, fill: str) -> list[str]:
    """Surround one rectangular semantic grid with a constant character."""
    inner_width = len(rows[0])
    horizontal = fill * padding
    framed_width = inner_width + padding * 2
    border = fill * framed_width
    return (
        [border] * padding
        + [horizontal + row + horizontal for row in rows]
        + [border] * padding
    )


def add_outer_frame(level: dict[str, object], padding: int) -> dict[str, object]:
    """Return semantic layers with X terrain and empty outer content cells."""
    terrain = level["terrain"]
    hazards = level["hazards"]
    entities = level["entities"]
    assert isinstance(terrain, list)
    assert isinstance(hazards, list)
    assert isinstance(entities, list)
    return {
        **level,
        "width": int(level["width"]) + padding * 2,
        "height": int(level["height"]) + padding * 2,
        "terrain": _pad_rows(terrain, padding, "X"),
        "hazards": _pad_rows(hazards, padding, "."),
        "entities": _pad_rows(entities, padding, "."),
    }


def strip_outer_frame(rows: list[str], padding: int) -> list[str]:
    """Return the algorithm-owned inner grid from a framed semantic layer."""
    if padding == 0:
        return list(rows)
    return [row[padding:-padding] for row in rows[padding:-padding]]
