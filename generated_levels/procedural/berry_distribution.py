"""Select a variable berry count using gameplay navigation distances."""

from __future__ import annotations

import math
import random
from dataclasses import dataclass
from typing import Callable

from . import config


Point = tuple[int, int]
DistanceMap = dict[Point, float]
DistanceMapFactory = Callable[[Point], DistanceMap]


@dataclass(frozen=True)
class BerryCandidate:
    """Describe one collectible position and its gameplay access point."""

    point: Point
    access_point: Point
    quality: float
    branch_depth: float
    guarded_enemies: frozenset[int]


def _point_distance(first: Point, second: Point) -> float:
    """Return direct semantic-cell distance between two rewards."""
    return math.dist(first, second)


def _is_spatially_clear(
    candidate: BerryCandidate, selected: list[BerryCandidate]
) -> bool:
    """Keep runtime reward footprints apart as before."""
    return all(
        _point_distance(candidate.point, other.point) >= config.BERRY_MIN_DISTANCE
        for other in selected
    )


def select_berry_candidates(
    candidates: list[BerryCandidate],
    base_target: int,
    distance_maps: DistanceMapFactory,
    rng: random.Random,
) -> list[BerryCandidate]:
    """Spread berries across branches and allow the target to vary by two."""
    minimum = max(config.MIN_BERRIES, base_target - config.BERRY_COUNT_VARIATION)
    maximum = base_target + config.BERRY_COUNT_VARIATION
    selected: list[BerryCandidate] = []
    remaining = list(candidates)
    path_distances = {candidate: math.inf for candidate in candidates}
    covered_enemies: set[int] = set()
    tie_breakers = {candidate: rng.random() for candidate in candidates}

    while len(selected) < maximum:
        usable = [
            candidate
            for candidate in remaining
            if _is_spatially_clear(candidate, selected)
            and path_distances[candidate] >= config.BERRY_MIN_PATH_DISTANCE
        ]
        if not usable:
            break
        if selected:
            farthest = max(path_distances[candidate] for candidate in usable)
            near_farthest = [
                candidate
                for candidate in usable
                if path_distances[candidate]
                >= farthest - config.BERRY_SPREAD_TOLERANCE
            ]
            has_uncovered_guard = any(
                candidate.guarded_enemies - covered_enemies for candidate in usable
            )
            if (
                len(selected) >= minimum
                and farthest < config.BERRY_COVERAGE_PATH_DISTANCE
                and not has_uncovered_guard
            ):
                break
            choice = max(
                near_farthest,
                key=lambda candidate: (
                    bool(candidate.guarded_enemies - covered_enemies),
                    candidate.branch_depth,
                    candidate.quality,
                    tie_breakers[candidate],
                ),
            )
        else:
            choice = max(
                usable,
                key=lambda candidate: (
                    candidate.branch_depth,
                    bool(candidate.guarded_enemies),
                    candidate.quality,
                    tie_breakers[candidate],
                ),
            )
        selected.append(choice)
        remaining.remove(choice)
        covered_enemies.update(choice.guarded_enemies)
        distances = distance_maps(choice.access_point)
        for candidate in remaining:
            path_distances[candidate] = min(
                path_distances[candidate],
                distances.get(candidate.access_point, math.inf),
            )

    if len(selected) < minimum:
        raise ValueError("The cave cannot distribute berries across distinct branches")
    return selected
