"""Plan enemy pacing from route scenes and type-specific geometry."""

from __future__ import annotations

import math
import random
from dataclasses import dataclass

from . import config
from .topology import build_navigation_search, navigation_distances


Point = tuple[int, int]
RouteMetric = tuple[Point, float]


@dataclass(frozen=True)
class EncounterZone:
    """Describe one local scene sampled along the main route."""

    center: Point
    stage: float
    openness: float
    branch_depth: float
    tension: float


def _local_openness(terrain: list[list[str]], point: Point, radius: int = 4) -> float:
    """Measure the air share around one route point."""
    x, y = point
    cells = [
        terrain[check_y][check_x]
        for check_y in range(max(0, y - radius), min(len(terrain), y + radius + 1))
        for check_x in range(max(0, x - radius), min(len(terrain[0]), x + radius + 1))
    ]
    return sum(cell in ".=" for cell in cells) / max(1, len(cells))


def build_encounter_zones(
    terrain: list[list[str]],
    route: list[RouteMetric],
    seed: int,
) -> tuple[EncounterZone, ...]:
    """Sample a deterministic low-frequency tension curve along the route."""
    rng = random.Random(seed ^ 0x5A4F4E4553)
    navigation = build_navigation_search(terrain, route[0][0])
    route_points = tuple(point for point, _ in route)
    branch_depths = navigation_distances(navigation.cells, route_points)
    zones: list[EncounterZone] = []
    for index in range(config.ENCOUNTER_ROUTE_ZONES):
        stage = (index + 0.5) / config.ENCOUNTER_ROUTE_ZONES
        route_point, actual_stage = min(route, key=lambda item: abs(item[1] - stage))
        nearby = [
            cell
            for cell in navigation.cells
            if math.dist(cell, route_point) <= 8.0
        ]
        point = max(
            nearby or [route_point],
            key=lambda cell: (
                branch_depths.get(cell, 0.0)
                + _local_openness(terrain, cell) * 2.0
                - math.dist(cell, route_point) * 0.08
            ),
        )
        wave = 0.5 + 0.28 * math.sin(index * 1.65 + rng.random() * 0.7)
        rest = 0.28 if index in (0, config.ENCOUNTER_ROUTE_ZONES - 1) else 0.0
        zones.append(
            EncounterZone(
                center=point,
                stage=actual_stage,
                openness=_local_openness(terrain, point),
                branch_depth=branch_depths.get(point, 0.0),
                tension=max(0.0, wave - rest + rng.uniform(-0.10, 0.10)),
            )
        )
    return tuple(zones)


def encounter_enemy_target(base_target: int, zones: tuple[EncounterZone, ...]) -> int:
    """Increase density only when the route contains enough roomy scenes."""
    roomy_scenes = sum(
        zone.openness >= 0.58 or zone.branch_depth >= 4.0 for zone in zones
    )
    maximum_bonus = round(base_target * config.ENCOUNTER_MAX_BONUS_RATIO)
    return base_target + min(maximum_bonus, roomy_scenes // 2)


def ordered_encounter_zones(
    zones: tuple[EncounterZone, ...], target: int
) -> tuple[EncounterZone, ...]:
    """Return a varied scene schedule while retaining deliberate rest zones."""
    active = sorted(
        zones[1:-1] or zones,
        key=lambda zone: (
            zone.tension + zone.openness * 0.35 + min(zone.branch_depth, 8.0) * 0.03
        ),
        reverse=True,
    )
    if not active:
        return ()
    return tuple(active[index % len(active)] for index in range(target))


def _floor_run_width(terrain: list[list[str]], point: Point) -> int:
    """Return the continuous visible-rock width under one anchor."""
    x, y = point
    left = x
    right = x
    while left > 0 and terrain[y][left - 1] == "#":
        left -= 1
    while right + 1 < len(terrain[0]) and terrain[y][right + 1] == "#":
        right += 1
    return right - left + 1


def candidate_suitability(
    terrain: list[list[str]],
    symbol: str,
    point: Point,
    stage: float,
    zone: EncounterZone,
) -> float:
    """Score an enemy anchor by scene fit, route stage, and patrol comfort."""
    distance = math.dist(point, zone.center)
    width = _floor_run_width(terrain, point)
    preferred_width = math.ceil(
        (
            config.ENTITY_FOOTPRINTS[symbol][2]
            - config.ENTITY_FOOTPRINTS[symbol][0]
            + config.ENTITY_PATROL_MARGIN[symbol]
        )
        / config.CELL_SIZE
    )
    comfort = min(1.0, width / max(1, preferred_width))
    patrol_shortfall = 1.0 - comfort
    type_bonus = 0.0
    if symbol == "K":
        type_bonus = 0.8 if width <= preferred_width else 0.2
    elif symbol == "B":
        type_bonus = zone.openness * 1.1 + comfort * 0.5
    else:
        type_bonus = comfort * 0.7
    return (
        abs(stage - zone.stage) * 7.0
        + distance * 0.035
        + patrol_shortfall * config.ENEMY_PATROL_SHORTFALL_COST
        - type_bonus
    )
