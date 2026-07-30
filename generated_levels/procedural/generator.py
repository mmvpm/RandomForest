"""Coordinate semantic terrain, feature, and entity generation."""

from __future__ import annotations

import secrets
from collections import Counter
from dataclasses import dataclass
from itertools import count
from typing import Callable

from . import config
from .cave import generate_cave
from .entities import enemy_target, place_entities
from .features import place_hazards, place_jump_throughs
from .frame import add_outer_frame
from .level_format import encode_level
from .morphology import MorphologyMetrics, morphology_is_qualified
from .star_times import calculate_star_times
from .topology import TopologyMetrics, topology_is_qualified
from .validation import validate_level


@dataclass(frozen=True)
class GenerationProgress:
    """Describe the current state of a multi-candidate generation run."""

    attempt: int
    stage: str
    valid_candidates: int
    target_candidates: int
    topology_rejected: int
    morphology_rejected: int
    content_rejected: int
    last_error: str | None = None


ProgressCallback = Callable[[GenerationProgress], None]


def _serialize(grid: list[list[str]]) -> list[str]:
    """Convert a mutable character grid to internal semantic rows."""
    return ["".join(row) for row in grid]


def _straight_edge_penalty(rows: list[str]) -> int:
    """Penalize long repeated horizontal and vertical silhouette segments."""
    height = len(rows)
    width = len(rows[0])
    penalty = 0
    for x in range(1, width - 1):
        run = 0
        for y in range(1, height - 1):
            exposed = rows[y][x] == "#" and (
                rows[y][x - 1] in ".=" or rows[y][x + 1] in ".="
            )
            run = run + 1 if exposed else 0
            if not exposed and run > 6:
                penalty += (run - 6) ** 2
            if not exposed:
                run = 0
        if run > 6:
            penalty += (run - 6) ** 2
    for y in range(1, height - 1):
        run = 0
        for x in range(1, width - 1):
            exposed = rows[y][x] == "#" and (
                rows[y - 1][x] in ".=" or rows[y + 1][x] in ".="
            )
            run = run + 1 if exposed else 0
            if not exposed and run > 8:
                penalty += (run - 8) ** 2
            if not exposed:
                run = 0
        if run > 8:
            penalty += (run - 8) ** 2
    return penalty


def _full_level_score(
    level: dict[str, object],
    topology: TopologyMetrics,
    morphology: MorphologyMetrics,
) -> float:
    """Score the final authored composition after every feature is present."""
    terrain_rows = level["terrain"]
    hazard_rows = level["hazards"]
    entity_rows = level["entities"]
    assert isinstance(terrain_rows, list)
    assert isinstance(hazard_rows, list)
    assert isinstance(entity_rows, list)
    terrain = Counter("".join(terrain_rows))
    hazards = Counter("".join(hazard_rows))
    entities = Counter("".join(entity_rows))
    area = int(level["width"]) * int(level["height"])
    air_ratio = terrain["."] / area
    hazard_count = sum(hazards[symbol] for symbol in "^v<>UDLR")
    enemy_count = sum(entities[symbol] for symbol in "SsKkBb")
    straight_edge_penalty = _straight_edge_penalty(terrain_rows)
    occupied_bands = {
        min(3, y * 4 // len(entity_rows))
        for y, row in enumerate(entity_rows)
        if any(symbol in "*SsKkBb" for symbol in row)
    }
    target_hazards = max(1, round(terrain["."] * config.HAZARD_AIR_RATIO))
    target_enemies = enemy_target(area)
    score = 150.0
    score -= abs(air_ratio - config.TARGET_AIR_RATIO) * 180.0
    score -= abs(
        morphology.external_rock_ratio - config.TARGET_EXTERNAL_ROCK_RATIO
    ) * 80.0
    score -= straight_edge_penalty * 0.35
    score -= abs(hazard_count - target_hazards) / target_hazards * 18.0
    score -= abs(enemy_count - target_enemies) * 2.5
    score += min(terrain["="], 26) * 0.25
    score += len(occupied_bands) * 4.0
    score += min(topology.detour_ratio, 5.0) * 12.0
    score += min(topology.horizontal_surface_ratio, 2.0) * 10.0
    score -= topology.long_sightline_ratio * 120.0
    return score


def generate_level(
    width_cells: int,
    height_cells: int,
    seed: int | None = None,
    topology: config.TopologySettings | None = None,
    progress: ProgressCallback | None = None,
) -> dict[str, object]:
    """Generate and select the best requested number of valid candidates."""
    if width_cells < config.MIN_WIDTH or height_cells < config.MIN_HEIGHT:
        raise ValueError(
            f"Level must be at least {config.MIN_WIDTH}x{config.MIN_HEIGHT} cells"
        )
    actual_seed = secrets.randbits(31) if seed is None else seed & 0x7FFFFFFF
    inner_width = width_cells - config.OUTER_X_PADDING * 2
    inner_height = height_cells - config.OUTER_X_PADDING * 2
    topology_settings = topology or config.DEFAULT_TOPOLOGY
    completed: list[tuple[float, dict[str, object]]] = []
    rejected_topology = 0
    rejected_morphology = 0
    rejected_content = 0

    def report(attempt: int, stage: str, error: str | None = None) -> None:
        """Publish one immutable progress snapshot when a callback is present."""
        if progress is None:
            return
        progress(
            GenerationProgress(
                attempt=attempt,
                stage=stage,
                valid_candidates=len(completed),
                target_candidates=topology_settings.valid_candidate_target,
                topology_rejected=rejected_topology,
                morphology_rejected=rejected_morphology,
                content_rejected=rejected_content,
                last_error=error,
            )
        )

    for retry in count():
        attempt = retry + 1
        report(attempt, "cave")
        generation_seed = (actual_seed + retry * 10_000_019) & 0x7FFFFFFF
        cave = generate_cave(inner_width, inner_height, generation_seed, topology_settings)
        if not topology_is_qualified(cave.topology, topology_settings):
            rejected_topology += 1
            report(attempt, "topology rejected")
            continue
        if not morphology_is_qualified(cave.morphology, topology_settings):
            rejected_morphology += 1
            report(attempt, "morphology rejected")
            continue
        try:
            report(attempt, "features")
            terrain = [row[:] for row in cave.terrain]
            air_count = len(cave.air)
            place_jump_throughs(terrain, air_count, generation_seed)
            hazards = place_hazards(terrain, air_count, cave.route, generation_seed)
            hazard_count = sum(
                cell in "^v<>UDLR" for row in hazards for cell in row
            )
            hazard_target = round(air_count * config.HAZARD_AIR_RATIO)
            if hazard_count < hazard_target * config.MIN_HAZARD_TARGET_RATIO:
                raise ValueError("The cave cannot support the requested hazard pacing")
            report(attempt, "entities")
            entities = place_entities(
                terrain,
                hazards,
                cave.route,
                generation_seed,
                topology_settings,
            )
            inner_level: dict[str, object] = {
                "width": inner_width,
                "height": inner_height,
                "style": {
                    "profile": "forest",
                    "seed": actual_seed,
                    "grass_chance": 0.4,
                },
                "terrain": _serialize(terrain),
                "hazards": _serialize(hazards),
                "entities": _serialize(entities),
            }
            level = add_outer_frame(inner_level, config.OUTER_X_PADDING)
            level["star_times"] = calculate_star_times(level)
            validate_level(level)
            completed.append(
                (
                    _full_level_score(
                        inner_level,
                        cave.topology,
                        cave.morphology,
                    ),
                    level,
                )
            )
            report(attempt, "accepted")
            if len(completed) >= topology_settings.valid_candidate_target:
                break
        except ValueError as error:
            rejected_content += 1
            report(attempt, "content rejected", str(error))
    selected = max(completed, key=lambda candidate: candidate[0])[1]
    return encode_level(selected)
