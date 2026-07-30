"""Shared pixel-footprint checks for generation and final validation."""

from __future__ import annotations

import math

from . import config


def footprint_cells(
    anchor_x: float, anchor_y: float, symbol: str
) -> tuple[int, int, int, int]:
    """Return inclusive semantic bounds for one runtime footprint."""
    left, top, right, bottom = config.ENTITY_FOOTPRINTS[symbol]
    return (
        math.floor((anchor_x + left) / config.CELL_SIZE),
        math.floor((anchor_y + top) / config.CELL_SIZE),
        math.floor((anchor_x + right - 1e-6) / config.CELL_SIZE),
        math.floor((anchor_y + bottom - 1e-6) / config.CELL_SIZE),
    )


def pixel_footprint_clear(
    terrain: list[list[str]] | list[str],
    anchor_x: float,
    anchor_y: float,
    symbol: str,
) -> bool:
    """Check one runtime footprint at an arbitrary pixel anchor."""
    first_x, first_y, last_x, last_y = footprint_cells(anchor_x, anchor_y, symbol)
    if (
        first_x < 0
        or first_y < 0
        or last_x >= len(terrain[0])
        or last_y >= len(terrain)
    ):
        return False
    return all(
        terrain[y][x] == "."
        for y in range(first_y, last_y + 1)
        for x in range(first_x, last_x + 1)
    )


def berry_has_safe_landing(
    terrain: list[list[str]] | list[str],
    hazards: list[list[str]] | list[str],
    point: tuple[int, int],
) -> bool:
    """Match the game's teleport search and require player-berry overlap."""
    berry_x = point[0] * config.CELL_SIZE
    berry_y = point[1] * config.CELL_SIZE
    target_y = berry_y + config.PLAYER_HEIGHT / 2
    player_left, player_top, player_right, player_bottom = (
        config.ENTITY_FOOTPRINTS["@"]
    )
    berry_left, berry_top, berry_right, berry_bottom = config.ENTITY_FOOTPRINTS["*"]
    radius = config.TELEPORT_SEARCH_RADIUS
    for distance in range(radius + 1):
        for direction_x in (-1, 0, 1):
            for direction_y in (-1, 0, 1):
                if distance == 0 and (direction_x != 0 or direction_y != 0):
                    continue
                if distance > 0 and direction_x == direction_y == 0:
                    continue
                anchor_x = berry_x + distance * direction_x
                anchor_y = target_y + distance * direction_y
                if not pixel_footprint_clear(terrain, anchor_x, anchor_y, "@"):
                    continue
                first_x, first_y, last_x, last_y = footprint_cells(
                    anchor_x, anchor_y, "@"
                )
                if any(
                    hazards[y][x] != "."
                    for y in range(first_y, last_y + 1)
                    for x in range(first_x, last_x + 1)
                ):
                    continue
                overlaps = (
                    anchor_x + player_left < berry_x + berry_right
                    and anchor_x + player_right > berry_x + berry_left
                    and anchor_y + player_top < berry_y + berry_bottom
                    and anchor_y + player_bottom > berry_y + berry_top
                )
                if overlaps:
                    return True
    return False
