"""Validate generated maps and generator-only gameplay invariants."""

from __future__ import annotations

import math

from . import config
from .features import spike_has_deep_backing, spike_run_has_side_backing
from .level_format import (
    ENTITY_SYMBOLS,
    HAZARD_SYMBOLS,
    TERRAIN_SYMBOLS,
    decode_level,
)
from .placement import berry_has_safe_landing, pixel_footprint_clear


def _validate_layer(level: dict[str, object], name: str, symbols: frozenset[str]) -> None:
    """Validate one rectangular ASCII layer and its symbol alphabet."""
    width = int(level["width"])
    height = int(level["height"])
    rows = level[name]
    if not isinstance(rows, list) or len(rows) != height:
        raise ValueError(f"{name} must contain exactly {height} rows")
    for row in rows:
        if not isinstance(row, str) or len(row) != width:
            raise ValueError(f"{name} rows must contain exactly {width} symbols")
        unknown = set(row) - symbols
        if unknown:
            raise ValueError(f"{name} contains unsupported symbols: {sorted(unknown)}")


def _validate_rock_shell(terrain: list[str]) -> None:
    """Require collision rock between playable air and collision-free dark mass."""
    height = len(terrain)
    width = len(terrain[0])
    for y in range(height):
        for x in range(width):
            if terrain[y][x] != "X":
                continue
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    if terrain[ny][nx] in ".=":
                        raise ValueError(f"Dark mass touches playable air at ({x}, {y})")


def _hazard_direction(symbol: str) -> str:
    """Normalize centered and aligned spike symbols to one direction."""
    directions = {
        "^": "up",
        "U": "up",
        "v": "down",
        "D": "down",
        "<": "left",
        "L": "left",
        ">": "right",
        "R": "right",
    }
    return directions[symbol]


def _hazard_runs(
    hazards: list[str],
) -> list[tuple[tuple[tuple[int, int], ...], str]]:
    """Collect contiguous spike runs with one normalized direction."""
    height = len(hazards)
    width = len(hazards[0])
    runs: list[tuple[tuple[tuple[int, int], ...], str]] = []
    for y in range(height):
        x = 0
        while x < width:
            symbol = hazards[y][x]
            if symbol not in "^UvD":
                x += 1
                continue
            direction = _hazard_direction(symbol)
            cells: list[tuple[int, int]] = []
            while (
                x < width
                and hazards[y][x] in "^UvD"
                and _hazard_direction(hazards[y][x]) == direction
            ):
                cells.append((x, y))
                x += 1
            runs.append((tuple(cells), direction))
    for x in range(width):
        y = 0
        while y < height:
            symbol = hazards[y][x]
            if symbol not in "<L>R":
                y += 1
                continue
            direction = _hazard_direction(symbol)
            cells = []
            while (
                y < height
                and hazards[y][x] in "<L>R"
                and _hazard_direction(hazards[y][x]) == direction
            ):
                cells.append((x, y))
                y += 1
            runs.append((tuple(cells), direction))
    return runs


def _spike_sections(
    x: int, y: int, symbol: str
) -> tuple[set[tuple[int, int]], set[tuple[int, int]], set[tuple[int, int]], set[tuple[int, int]]]:
    """Return tip, trap, solid, and base cells on the runtime 6-pixel grid."""
    if symbol in "U^":
        offsets = (0, 1, 2, 3) if symbol == "U" else (-1, 0, 1, 2)
        return tuple(
            {(x * 2 + cross, y * 2 + offset) for cross in range(2)}
            for offset in offsets
        )  # type: ignore[return-value]
    if symbol in "Dv":
        offsets = (1, 0, -1, -2) if symbol == "D" else (2, 1, 0, -1)
        return tuple(
            {(x * 2 + cross, y * 2 + offset) for cross in range(2)}
            for offset in offsets
        )  # type: ignore[return-value]
    if symbol in "L<":
        offsets = (0, 1, 2, 3) if symbol == "L" else (-1, 0, 1, 2)
        return tuple(
            {(x * 2 + offset, y * 2 + cross) for cross in range(2)}
            for offset in offsets
        )  # type: ignore[return-value]
    offsets = (1, 0, -1, -2) if symbol == "R" else (2, 1, 0, -1)
    return tuple(
        {(x * 2 + offset, y * 2 + cross) for cross in range(2)}
        for offset in offsets
    )  # type: ignore[return-value]


def _validate_hazards(terrain: list[str], hazards: list[str]) -> None:
    """Require open tips, visible-rock bases, and non-singleton spike runs."""
    height = len(terrain)
    width = len(terrain[0])
    rock_fine = {
        (x * 2 + dx, y * 2 + dy)
        for y in range(height)
        for x in range(width)
        if terrain[y][x] == "#"
        for dx in range(2)
        for dy in range(2)
    }
    sections = {
        (x, y): _spike_sections(x, y, hazards[y][x])
        for y in range(height)
        for x in range(width)
        if hazards[y][x] != "."
    }
    for cells, direction in _hazard_runs(hazards):
        if not spike_run_has_side_backing(terrain, cells, direction):
            raise ValueError(f"Spike sides lack deep black backing at {cells[0]}")
    for y in range(height):
        for x in range(width):
            symbol = hazards[y][x]
            if symbol == ".":
                continue
            direction = _hazard_direction(symbol)
            if terrain[y][x] != ".":
                raise ValueError(f"Spike overlaps terrain at ({x}, {y})")
            if direction == "up":
                neighbors = ((x - 1, y), (x + 1, y))
            elif direction == "down":
                neighbors = ((x - 1, y), (x + 1, y))
            elif direction == "left":
                neighbors = ((x, y - 1), (x, y + 1))
            else:
                neighbors = ((x, y - 1), (x, y + 1))
            tip_cells, trap_cells, _, base_cells = sections[(x, y)]
            if (tip_cells | trap_cells) & rock_fine:
                raise ValueError(f"Spike tip intersects visible rock at ({x}, {y})")
            other_rear = set().union(
                *(
                    other_solid | other_base
                    for point, (_, _, other_solid, other_base) in sections.items()
                    if point != (x, y)
                )
            )
            if not all(cell in rock_fine or cell in other_rear for cell in base_cells):
                raise ValueError(f"Spike base is unsupported at ({x}, {y})")
            if not spike_has_deep_backing(terrain, hazards, x, y, symbol):
                raise ValueError(f"Spike backing is only one cell deep at ({x}, {y})")
            if not any(
                0 <= nx < width
                and 0 <= ny < height
                and hazards[ny][nx] == symbol
                for nx, ny in neighbors
            ):
                raise ValueError(f"Spike run is only one cell long at ({x}, {y})")


def _validate_jump_throughs(terrain: list[str]) -> None:
    """Require every jump-through run to be horizontally anchored and usable."""
    height = len(terrain)
    width = len(terrain[0])
    for y in range(height):
        x = 0
        while x < width:
            if terrain[y][x] != "=":
                x += 1
                continue
            start = x
            while x < width and terrain[y][x] == "=":
                x += 1
            length = x - start
            if not config.JUMP_THRU_MIN_LENGTH <= length <= config.JUMP_THRU_MAX_LENGTH:
                raise ValueError(f"Invalid jump-through length at ({start}, {y})")
            left_anchor = start > 0 and terrain[y][start - 1] == "#"
            right_anchor = x < width and terrain[y][x] == "#"
            if not (left_anchor or right_anchor):
                raise ValueError(f"Jump-through floats at ({start}, {y})")
            for platform_x in range(start, x):
                if any(
                    terrain[check_y][platform_x] not in ".="
                    for check_y in range(y - 3, y)
                ):
                    raise ValueError(f"Jump-through lacks headroom at ({platform_x}, {y})")


def _footprint_clear(terrain: list[str], x: int, y: int, symbol: str) -> bool:
    """Check one cell-anchored runtime footprint against terrain."""
    return pixel_footprint_clear(
        terrain, x * config.CELL_SIZE, y * config.CELL_SIZE, symbol
    )


def _validate_entities(terrain: list[str], hazards: list[str], entities: list[str]) -> None:
    """Validate singleton entities and conservative placement footprints."""
    text = "".join(entities)
    if text.count("@") != 1:
        raise ValueError("The generated map must contain exactly one player")
    if text.count("O") + text.count("o") != 1:
        raise ValueError("The generated map must contain exactly one door")
    for y, row in enumerate(entities):
        for x, symbol in enumerate(row):
            upper = symbol.upper()
            if symbol == ".":
                continue
            if upper in ("@", "S", "K", "B"):
                if terrain[y][x] != "#":
                    raise ValueError(f"Ground entity lacks a floor anchor at ({x}, {y})")
                left_px, top_px, right_px, _ = config.ENTITY_FOOTPRINTS[upper]
                floor_width = math.ceil(
                    (
                        right_px
                        - left_px
                        + config.ENTITY_PATROL_MARGIN[upper]
                    )
                    / config.CELL_SIZE
                )
                headroom = math.ceil(abs(top_px) / config.CELL_SIZE)
                left = x - (floor_width - 1) // 2
                right = left + floor_width
                if left < 0 or right > len(row) or y - headroom < 0:
                    raise ValueError(f"Ground entity footprint leaves the map at ({x}, {y})")
                if any(terrain[y][floor_x] != "#" for floor_x in range(left, right)):
                    raise ValueError(f"Ground entity platform is too short at ({x}, {y})")
                if any(
                    terrain[air_y][floor_x] != "."
                    for air_y in range(y - headroom, y)
                    for floor_x in range(left, right)
                ):
                    raise ValueError(f"Ground entity lacks headroom at ({x}, {y})")
                if not _footprint_clear(terrain, x, y, upper):
                    raise ValueError(f"Ground entity pixel footprint is blocked at ({x}, {y})")
                hazard_nearby = any(
                    hazards[check_y][check_x] != "."
                    for check_y in range(max(0, y - 2), y + 1)
                    for check_x in range(max(0, x - 2), min(len(row), x + 3))
                )
                if hazard_nearby:
                    raise ValueError(f"Ground entity is too close to spikes at ({x}, {y})")
            elif upper == "O":
                floor_y = y + 2
                if floor_y >= len(terrain) or terrain[floor_y][x] != "#":
                    raise ValueError(f"Door lacks its expected floor at ({x}, {y})")
                if any(
                    terrain[check_y][check_x] != "."
                    for check_y in range(max(0, y - 2), floor_y)
                    for check_x in range(max(0, x - 1), min(len(row), x + 2))
                ):
                    raise ValueError(f"Door visual footprint is obstructed at ({x}, {y})")
                if not _footprint_clear(terrain, x, y, "O"):
                    raise ValueError(f"Door pixel footprint is blocked at ({x}, {y})")
            elif symbol == "*":
                if not _footprint_clear(terrain, x, y, "*"):
                    raise ValueError(f"Berry pixel footprint is blocked at ({x}, {y})")
                if not berry_has_safe_landing(terrain, hazards, (x, y)):
                    raise ValueError(f"Berry has no safe collection landing at ({x}, {y})")


def validate_level(level: dict[str, object]) -> None:
    """Validate the full format contract and procedural geometry invariants."""
    semantic = decode_level(level) if "map" in level else level
    width = semantic.get("width")
    height = semantic.get("height")
    if not isinstance(width, int) or not isinstance(height, int):
        raise ValueError("Level dimensions must be integers")
    if width < config.MIN_WIDTH or height < config.MIN_HEIGHT:
        raise ValueError(f"Level must be at least {config.MIN_WIDTH}x{config.MIN_HEIGHT} cells")
    room_diagonal = math.hypot(width * config.CELL_SIZE, height * config.CELL_SIZE)
    if room_diagonal > config.SWORD_FLIGHT_RANGE * 1.1:
        raise ValueError("Level is larger than the supported sword-flight envelope")
    style = semantic.get("style")
    if not isinstance(style, dict):
        raise ValueError("style must be an object")
    if style.get("profile") != "forest":
        raise ValueError("style must use the forest profile")
    if not isinstance(style.get("seed"), int):
        raise ValueError("style.seed must be an integer")
    star_times = semantic.get("star_times")
    if star_times is not None:
        if not isinstance(star_times, dict):
            raise ValueError("star_times must be an object")
        three_stars = star_times.get("three_stars")
        two_stars = star_times.get("two_stars")
        if (
            not isinstance(three_stars, int)
            or not isinstance(two_stars, int)
            or three_stars <= 0
            or two_stars != three_stars * config.TWO_STAR_TIME_FACTOR
        ):
            raise ValueError(
                "star_times must contain positive 3-star and 2-star seconds"
            )
    _validate_layer(semantic, "terrain", TERRAIN_SYMBOLS)
    _validate_layer(semantic, "hazards", HAZARD_SYMBOLS)
    _validate_layer(semantic, "entities", ENTITY_SYMBOLS)
    terrain = semantic["terrain"]
    hazards = semantic["hazards"]
    entities = semantic["entities"]
    assert isinstance(terrain, list) and isinstance(hazards, list) and isinstance(entities, list)
    _validate_rock_shell(terrain)
    _validate_hazards(terrain, hazards)
    _validate_jump_throughs(terrain)
    _validate_entities(terrain, hazards, entities)
