"""Measure cave composition independently from navigation topology."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass

from . import config


@dataclass(frozen=True)
class MorphologyMetrics:
    """Describe the silhouette properties that previously regressed visually."""

    external_rock_ratio: float
    playable_bbox_ratio: float
    maximum_flat_run: int
    central_open_span_ratio: float


def _runs(values: list[bool]) -> list[int]:
    """Return lengths of continuous true runs."""
    result: list[int] = []
    length = 0
    for value in values + [False]:
        if value:
            length += 1
        elif length:
            result.append(length)
            length = 0
    return result


def _external_rock(terrain: list[list[str]]) -> set[tuple[int, int]]:
    """Return X cells connected orthogonally to the canvas border."""
    height = len(terrain)
    width = len(terrain[0])
    border = {
        (x, y)
        for y in range(height)
        for x in range(width)
        if terrain[y][x] == "X" and (x in (0, width - 1) or y in (0, height - 1))
    }
    result = set(border)
    queue = deque(border)
    while queue:
        x, y = queue.popleft()
        for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            nx, ny = point
            if not (0 <= nx < width and 0 <= ny < height):
                continue
            if point in result or terrain[ny][nx] != "X":
                continue
            result.add(point)
            queue.append(point)
    return result


def _maximum_flat_run(terrain: list[list[str]]) -> int:
    """Return the longest exposed horizontal collision surface."""
    lengths: list[int] = []
    for y in range(1, len(terrain) - 1):
        lengths.extend(
            _runs(
                [
                    terrain[y][x] == "#"
                    and (terrain[y - 1][x] == "." or terrain[y + 1][x] == ".")
                    for x in range(len(terrain[0]))
                ]
            )
        )
    return max(lengths, default=0)


def analyze_morphology(terrain: list[list[str]] | list[str]) -> MorphologyMetrics:
    """Measure external mass, canvas coverage, open spans, and straight ledges."""
    grid = [list(row) for row in terrain]
    height = len(grid)
    width = len(grid[0])
    air = [(x, y) for y, row in enumerate(grid) for x, cell in enumerate(row) if cell == "."]
    xs = [x for x, _ in air]
    ys = [y for _, y in air]
    bbox_area = (
        (max(xs) - min(xs) + 1) * (max(ys) - min(ys) + 1)
        if air
        else 0
    )
    center_spans = [
        max(_runs([cell == "." for cell in grid[y]]), default=0)
        for y in range(height // 4, 3 * height // 4)
    ]
    center_spans.sort()
    percentile_index = round(max(0, len(center_spans) - 1) * 0.9)
    return MorphologyMetrics(
        external_rock_ratio=len(_external_rock(grid)) / (width * height),
        playable_bbox_ratio=bbox_area / (width * height),
        maximum_flat_run=_maximum_flat_run(grid),
        central_open_span_ratio=(
            center_spans[percentile_index] / width if center_spans else 0.0
        ),
    )


def collision_depth_is_qualified(terrain: list[list[str]] | list[str]) -> bool:
    """Return whether visible collision rock stays within two cells of air."""
    grid = [list(row) for row in terrain]
    height = len(grid)
    width = len(grid[0])
    return all(
        grid[y][x] != "#"
        or any(
            grid[check_y][check_x] in ".="
            for check_y in range(max(0, y - 2), min(height, y + 3))
            for check_x in range(max(0, x - 2), min(width, x + 3))
        )
        for y in range(height)
        for x in range(width)
    )


def morphology_is_qualified(
    metrics: MorphologyMetrics,
    settings: config.TopologySettings,
) -> bool:
    """Reject only the silhouette extremes identified by visual comparison."""
    return (
        settings.min_external_rock_ratio
        <= metrics.external_rock_ratio
        <= settings.max_external_rock_ratio
        and 0.82 <= metrics.playable_bbox_ratio <= 0.97
        and metrics.maximum_flat_run <= config.MAX_FLAT_SURFACE_RUN
        and metrics.central_open_span_ratio <= config.MAX_CENTRAL_OPEN_SPAN_RATIO
    )
