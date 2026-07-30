"""Convert between editable maps and internal semantic layers."""

from __future__ import annotations


TERRAIN_SYMBOLS = frozenset(".#X=")
HAZARD_SYMBOLS = frozenset(".^v<>UDLR")
ENTITY_SYMBOLS = frozenset(".@Oo*SsKkBbPp")
GROUND_ENTITY_SYMBOLS = frozenset("@SsKkBbPp")
MAP_SYMBOLS = TERRAIN_SYMBOLS | HAZARD_SYMBOLS | ENTITY_SYMBOLS


def _read_rows(
    level: dict[str, object],
    name: str,
    symbols: frozenset[str],
) -> list[str]:
    """Return one rectangular character grid from a level dictionary."""
    width = level.get("width")
    height = level.get("height")
    rows = level.get(name)
    if not isinstance(width, int) or not isinstance(height, int):
        raise ValueError("Level dimensions must be integers")
    if not isinstance(rows, list) or len(rows) != height:
        raise ValueError(f"{name} must contain exactly {height} rows")
    for row in rows:
        if not isinstance(row, str) or len(row) != width:
            raise ValueError(f"{name} rows must contain exactly {width} symbols")
        unknown = set(row) - symbols
        if unknown:
            raise ValueError(f"{name} contains unsupported symbols: {sorted(unknown)}")
    return rows


def _empty_grid(width: int, height: int) -> list[list[str]]:
    """Create an empty mutable semantic grid."""
    return [["."] * width for _ in range(height)]


def _place_symbol(
    grid: list[list[str]],
    x: int,
    y: int,
    symbol: str,
    description: str,
) -> None:
    """Place one symbol while rejecting an ambiguous map coordinate."""
    if y < 0 or y >= len(grid):
        raise ValueError(f"{description} at ({x}, {y}) leaves the map")
    existing = grid[y][x]
    if existing != ".":
        raise ValueError(
            f"{description} at ({x}, {y}) overlaps existing symbol {existing!r}"
        )
    grid[y][x] = symbol


def decode_level(level: dict[str, object]) -> dict[str, object]:
    """Return a level with the three internal semantic layers available."""
    width = level.get("width")
    height = level.get("height")
    if not isinstance(width, int) or not isinstance(height, int):
        raise ValueError("Level dimensions must be integers")
    map_rows = _read_rows(level, "map", MAP_SYMBOLS)
    terrain = _empty_grid(width, height)
    hazards = _empty_grid(width, height)
    entities = _empty_grid(width, height)

    for y, row in enumerate(map_rows):
        for x, symbol in enumerate(row):
            if symbol == ".":
                continue
            if symbol in TERRAIN_SYMBOLS:
                terrain[y][x] = symbol
            elif symbol in HAZARD_SYMBOLS:
                hazards[y][x] = symbol
            else:
                anchor_y = y + 1 if symbol in GROUND_ENTITY_SYMBOLS else y
                _place_symbol(
                    entities,
                    x,
                    anchor_y,
                    symbol,
                    f"Entity {symbol!r}",
                )

    return {
        **level,
        "terrain": ["".join(row) for row in terrain],
        "hazards": ["".join(row) for row in hazards],
        "entities": ["".join(row) for row in entities],
    }


def encode_level(level: dict[str, object]) -> dict[str, object]:
    """Return a canonical level with one editable ASCII map."""
    semantic = decode_level(level) if "map" in level else dict(level)
    width = semantic.get("width")
    height = semantic.get("height")
    if not isinstance(width, int) or not isinstance(height, int):
        raise ValueError("Level dimensions must be integers")
    terrain = _read_rows(semantic, "terrain", TERRAIN_SYMBOLS)
    hazards = _read_rows(semantic, "hazards", HAZARD_SYMBOLS)
    entities = _read_rows(semantic, "entities", ENTITY_SYMBOLS)
    merged = _empty_grid(width, height)

    for y in range(height):
        for x in range(width):
            terrain_symbol = terrain[y][x]
            if terrain_symbol != ".":
                _place_symbol(merged, x, y, terrain_symbol, "Terrain")
            hazard_symbol = hazards[y][x]
            if hazard_symbol != ".":
                _place_symbol(merged, x, y, hazard_symbol, "Hazard")
            entity_symbol = entities[y][x]
            if entity_symbol != ".":
                display_y = y - 1 if entity_symbol in GROUND_ENTITY_SYMBOLS else y
                _place_symbol(
                    merged,
                    x,
                    display_y,
                    entity_symbol,
                    f"Entity {entity_symbol!r}",
                )

    encoded = {
        key: value
        for key, value in semantic.items()
        if key not in ("terrain", "hazards", "entities", "map")
    }
    encoded["map"] = ["".join(row) for row in merged]
    return encoded
