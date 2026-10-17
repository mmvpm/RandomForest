"""Validate editor-authored prop groups independently of procedural placement."""

from functools import lru_cache
import json
import math
from pathlib import Path


@lru_cache(maxsize=1)
def prop_types() -> frozenset[str]:
    """Read stable slugs from the same bundled catalogue as the editor and game."""
    path = Path(__file__).resolve().parents[2] / "RandomForest/datafiles/world_props/catalog.json"
    return frozenset(item["slug"] for item in json.loads(path.read_text())["props"])


def _collision_cells(prop: dict, field: str, width: int, height: int) -> set[tuple[int, int]]:
    """Validate and reflect one local collision list, including an absent one-way list."""
    rows = prop.get(field, [])
    if not isinstance(rows, list):
        raise ValueError(f"Prop {field} must be an array")
    cells = set()
    for cell in rows:
        if not isinstance(cell, list) or len(cell) != 2 or any(type(value) is not int for value in cell):
            raise ValueError("Prop collision cell must contain two integer coordinates")
        x = prop["x"] // 6 + (-cell[0] - 1 if prop["mirrored"] else cell[0])
        y = prop["y"] // 6 + cell[1]
        if not 0 <= x < width * 2 or not 0 <= y < height * 2:
            raise ValueError("Prop collision leaves the room")
        cells.add((x, y))
    return cells


def prop_collision_cells(level: dict) -> tuple[set[tuple[int, int]], set[tuple[int, int]]]:
    """Validate groups and keep solid obstacles separate from one-way support cells."""
    props = level.get("props", [])
    if not isinstance(props, list):
        raise ValueError("props must be an array")
    ids, solids, jump_thrus = set(), set(), set()
    for prop in props:
        if not isinstance(prop, dict) or not {"id", "type", "x", "y", "mirrored", "solids"} <= prop.keys():
            raise ValueError("Prop is missing required fields")
        if not isinstance(prop["id"], str) or not prop["id"] or prop["id"] in ids:
            raise ValueError("Prop IDs must be unique non-empty strings")
        ids.add(prop["id"])
        if not isinstance(prop["type"], str) or prop["type"] not in prop_types():
            raise ValueError("Unknown prop type")
        if any(type(prop[key]) is not int or prop[key] % 6 for key in ("x", "y")):
            raise ValueError("Prop positions must use the integer 6 px grid")
        if not 0 <= prop["x"] <= level["width"] * 12 or not 0 <= prop["y"] <= level["height"] * 12:
            raise ValueError("Prop anchor leaves the room")
        if type(prop["mirrored"]) is not bool or not isinstance(prop["solids"], list):
            raise ValueError("Invalid prop reflection or solid cells")
        opacity = prop.get("opacity", 100)
        if type(opacity) is not int or not 0 <= opacity <= 100:
            raise ValueError("Prop opacity must be an integer from 0 to 100")
        if prop.get("platform_layer", "above") not in ("above", "below"):
            raise ValueError("Prop platform_layer must be above or below")
        solids.update(_collision_cells(prop, "solids", level["width"], level["height"]))
        jump_thrus.update(_collision_cells(prop, "jump_thrus", level["width"], level["height"]))
    return solids, jump_thrus


def prop_solid_cells(level: dict) -> set[tuple[int, int]]:
    """Return only full obstacles for callers that do not need one-way support cells."""
    return prop_collision_cells(level)[0]


def has_support(terrain: list[str], cells: set[tuple[int, int]], left: float, right: float, y: int) -> bool:
    """Require continuous support under a pixel footprint from terrain or prop solids."""
    if y < 0 or y >= len(terrain) * 12 or left < 0 or right > len(terrain[0]) * 12:
        return False
    return all(terrain[y // 12][x // 2] == "#" or (x, y // 6) in cells
               for x in range(math.floor(left / 6), math.ceil(right / 6)))
