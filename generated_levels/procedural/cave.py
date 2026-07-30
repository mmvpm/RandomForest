"""Convert production skeleton air into semantic cave terrain."""

from __future__ import annotations

from dataclasses import dataclass

from . import config
from .geometry import warped_fbm
from .morphology import (
    MorphologyMetrics,
    analyze_morphology,
    morphology_is_qualified,
)
from .skeleton import generate_skeleton_air, rasterize_looped_skeleton
from .skeleton_quality import SkeletonMetrics
from .topology import TopologyMetrics, analyze_topology, topology_is_qualified


@dataclass(frozen=True)
class CaveResult:
    """Contain one cave plus navigation and composition diagnostics."""

    terrain: list[list[str]]
    air: set[tuple[int, int]]
    route: tuple[tuple[int, int], ...]
    score: float
    topology: TopologyMetrics
    morphology: MorphologyMetrics
    skeleton: SkeletonMetrics


def _terrain_from_air(air: list[list[bool]], seed: int) -> list[list[str]]:
    """Back carved air with X mass and a continuous visible collision shell."""
    height = len(air)
    width = len(air[0])
    terrain = [["." if air[y][x] else "X" for x in range(width)] for y in range(height)]
    for y in range(height):
        for x in range(width):
            if air[y][x]:
                continue
            if any(
                0 <= nx < width and 0 <= ny < height and air[ny][nx]
                for ny in range(y - 1, y + 2)
                for nx in range(x - 1, x + 2)
            ):
                terrain[y][x] = "#"
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            if terrain[y][x] != "X" or warped_fbm(seed ^ 0x5348454C4C, x, y) <= 0.32:
                continue
            if any(
                terrain[ny][nx] == "#"
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
            ):
                terrain[y][x] = "#"
    return terrain


def _composition_score(
    topology: TopologyMetrics,
    morphology: MorphologyMetrics,
) -> float:
    """Rank valid caves without allowing one aggregate metric to hide defects."""
    score = 100.0
    score -= abs(topology.air_ratio - config.TARGET_AIR_RATIO) * 100.0
    score -= abs(
        morphology.external_rock_ratio - config.TARGET_EXTERNAL_ROCK_RATIO
    ) * 140.0
    score += min(topology.detour_ratio, 4.0) * 5.0
    score += min(topology.horizontal_surface_ratio, 2.0) * 4.0
    score -= morphology.maximum_flat_run * 0.12
    return score


def _build_cave_result(
    air_grid: list[list[bool]], seed: int, skeleton: SkeletonMetrics
) -> CaveResult:
    """Convert and analyze one already selected skeleton raster."""
    terrain = _terrain_from_air(air_grid, seed)
    air = {
        (x, y)
        for y, row in enumerate(terrain)
        for x, value in enumerate(row)
        if value == "."
    }
    topology = analyze_topology(terrain)
    morphology = analyze_morphology(terrain)
    return CaveResult(
        terrain=terrain,
        air=air,
        route=topology.route,
        score=_composition_score(topology, morphology),
        topology=topology,
        morphology=morphology,
        skeleton=skeleton,
    )


def generate_cave(
    width: int,
    height: int,
    seed: int,
    settings: config.TopologySettings = config.DEFAULT_TOPOLOGY,
) -> CaveResult:
    """Generate one base cave and safely prefer its qualified ring variant."""
    skeleton = generate_skeleton_air(width, height, seed, settings)
    base = _build_cave_result(skeleton.base_air, seed, skeleton.base_metrics)
    base_is_qualified = topology_is_qualified(
        base.topology, settings
    ) and morphology_is_qualified(base.morphology, settings)
    if not base_is_qualified:
        return base
    looped_skeleton = rasterize_looped_skeleton(
        skeleton,
        width,
        height,
        seed,
        settings.corridor_width_scale,
    )
    if looped_skeleton is None:
        return base
    looped_air, looped_metrics = looped_skeleton
    looped = _build_cave_result(
        looped_air,
        seed,
        looped_metrics,
    )
    if topology_is_qualified(
        looped.topology, settings
    ) and morphology_is_qualified(looped.morphology, settings):
        return looped
    return base
