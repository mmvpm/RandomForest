"""Analyze authored gameplay composition independently from cave geometry."""

from __future__ import annotations

import math
from dataclasses import dataclass

from . import config
from .affordance import analyze_affordances
from .encounters import build_encounter_zones, candidate_suitability
from .topology import build_navigation_search


Point = tuple[int, int]


@dataclass(frozen=True)
class CompositionMetrics:
    """Describe pacing, rewards, encounters, and traversal features."""

    occupied_stages: int
    longest_empty_stage_run: int
    overcrowded_stages: int
    deep_rewards: int
    guarded_rewards: int
    useful_platform_runs: int
    isolated_platform_runs: int
    repeated_enemy_pairs: int
    encounter_fit_cost: float


def _route_metrics(route: tuple[Point, ...]) -> list[tuple[Point, float]]:
    """Attach normalized arclength to one concrete player route."""
    distances = [0.0]
    for first, second in zip(route, route[1:]):
        distances.append(distances[-1] + math.dist(first, second))
    total = max(1.0, distances[-1])
    return [(point, distance / total) for point, distance in zip(route, distances)]


def _stage(point: Point, route: list[tuple[Point, float]]) -> float:
    """Project one content point onto its closest route stage."""
    return min(route, key=lambda item: math.dist(point, item[0]))[1]


def _longest_empty_run(counts: list[int]) -> int:
    """Return the longest consecutive sequence of content-free stages."""
    longest = 0
    current = 0
    for count in counts:
        current = current + 1 if count == 0 else 0
        longest = max(longest, current)
    return longest


def _platform_centers(terrain: list[list[str]]) -> list[Point]:
    """Return one center point for every horizontal jump-through run."""
    centers: list[Point] = []
    for y, row in enumerate(terrain):
        x = 0
        while x < len(row):
            if row[x] != "=":
                x += 1
                continue
            start = x
            while x < len(row) and row[x] == "=":
                x += 1
            centers.append(((start + x - 1) // 2, y))
    return centers


def composition_route(
    terrain: list[list[str]] | list[str],
    entities: list[list[str]] | list[str],
) -> tuple[Point, ...]:
    """Recover the concrete player-to-door route used by the final composition."""
    player: Point | None = None
    door: Point | None = None
    for y, row in enumerate(entities):
        for x, symbol in enumerate(row):
            if symbol == "@":
                player = (x, y)
            elif symbol in "Oo":
                door = (x, y)
    if player is None or door is None:
        return ()
    return build_navigation_search(terrain, player).path_to(door)


def analyze_composition(
    terrain: list[list[str]] | list[str],
    hazards: list[list[str]] | list[str],
    entities: list[list[str]] | list[str],
    route: tuple[Point, ...],
    seed: int,
) -> CompositionMetrics:
    """Measure local scene rhythm without changing or validating the level."""
    terrain_grid = [list(row) for row in terrain]
    hazard_grid = [list(row) for row in hazards]
    entity_grid = [list(row) for row in entities]
    route_metrics = _route_metrics(route)
    if not route_metrics:
        return CompositionMetrics(0, config.ENCOUNTER_ROUTE_ZONES, 0, 0, 0, 0, 0, 0, 100.0)
    enemies = [
        ((x, y), symbol.upper())
        for y, row in enumerate(entity_grid)
        for x, symbol in enumerate(row)
        if symbol in "SsKkBb"
    ]
    berries = [
        (x, y)
        for y, row in enumerate(entity_grid)
        for x, symbol in enumerate(row)
        if symbol == "*"
    ]
    platforms = _platform_centers(terrain_grid)
    stage_counts = [0] * config.ENCOUNTER_ROUTE_ZONES
    for point in [point for point, _ in enemies] + berries + platforms:
        index = min(
            config.ENCOUNTER_ROUTE_ZONES - 1,
            int(_stage(point, route_metrics) * config.ENCOUNTER_ROUTE_ZONES),
        )
        stage_counts[index] += 1
    deep_rewards = sum(
        min(math.dist(berry, route_point) for route_point, _ in route_metrics) >= 4.0
        for berry in berries
    )
    guarded_rewards = sum(
        any(
            config.BERRY_GUARD_MIN_DISTANCE
            <= math.dist(berry, enemy)
            <= config.BERRY_GUARD_MAX_DISTANCE
            for enemy, _ in enemies
        )
        for berry in berries
    )
    ordered_enemies = sorted(enemies, key=lambda item: _stage(item[0], route_metrics))
    repeated_pairs = sum(
        first[1] == second[1]
        for first, second in zip(ordered_enemies, ordered_enemies[1:])
    )
    zones = build_encounter_zones(terrain_grid, route_metrics, seed)
    fit_cost = 0.0
    for point, symbol in enemies:
        stage = _stage(point, route_metrics)
        zone = min(zones, key=lambda candidate: abs(candidate.stage - stage))
        fit_cost += max(
            0.0,
            candidate_suitability(terrain_grid, symbol, point, stage, zone),
        )
    affordances = analyze_affordances(terrain_grid, hazard_grid)
    return CompositionMetrics(
        occupied_stages=sum(count > 0 for count in stage_counts),
        longest_empty_stage_run=_longest_empty_run(stage_counts),
        overcrowded_stages=sum(max(0, count - 4) for count in stage_counts),
        deep_rewards=deep_rewards,
        guarded_rewards=guarded_rewards,
        useful_platform_runs=affordances.useful_platform_runs,
        isolated_platform_runs=affordances.isolated_platform_runs,
        repeated_enemy_pairs=repeated_pairs,
        encounter_fit_cost=fit_cost,
    )


def composition_score(metrics: CompositionMetrics) -> float:
    """Rank deliberate scene composition while retaining valuable empty beats."""
    score = metrics.occupied_stages * 3.0
    score -= max(0, metrics.longest_empty_stage_run - 1) ** 2 * 2.0
    score -= metrics.overcrowded_stages * 1.5
    score += metrics.deep_rewards * 3.0
    score += metrics.guarded_rewards * 1.25
    score += metrics.useful_platform_runs * 2.0
    score -= metrics.isolated_platform_runs * 6.0
    score -= metrics.repeated_enemy_pairs * 0.6
    score -= metrics.encounter_fit_cost * 0.20
    return score
