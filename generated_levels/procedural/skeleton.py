"""Generate a cave field from a winding planar route skeleton."""

from __future__ import annotations

import math
import random
from dataclasses import dataclass

from . import config
from .geometry import FloatPoint, hash_unit, largest_component, value_noise, warped_fbm
from .skeleton_quality import (
    SkeletonMetrics,
    analyze_skeleton,
    select_loop_edges,
    should_add_loop,
)


@dataclass(frozen=True)
class SkeletonAirResult:
    """Contain one base raster and graph data for an optional loop variant."""

    base_air: list[list[bool]]
    base_metrics: SkeletonMetrics
    nodes: list[FloatPoint]
    tree_edges: list[tuple[int, int]]
    loop_edges: list[tuple[int, int]]


def _jittered_lattice(
    width: int, height: int, rng: random.Random
) -> tuple[list[FloatPoint], list[tuple[int, int]], dict[tuple[int, int], int]]:
    """Distribute graph controls across the canvas without regular raster alignment."""
    columns = max(4, math.ceil((width - 6) / config.SKELETON_STEP_X))
    rows = max(3, math.ceil((height - 6) / config.SKELETON_STEP_Y))
    cell_width = (width - 6) / max(1, columns - 1)
    cell_height = (height - 6) / max(1, rows - 1)
    nodes: list[FloatPoint] = []
    coordinates: list[tuple[int, int]] = []
    lookup: dict[tuple[int, int], int] = {}
    for row in range(rows):
        for column in range(columns):
            x = 3 + column * cell_width + rng.uniform(-0.24, 0.24) * cell_width
            y = 3 + row * cell_height + rng.uniform(-0.24, 0.24) * cell_height
            point = (
                max(2.5, min(width - 3.5, x)),
                max(2.5, min(height - 3.5, y)),
            )
            lookup[(column, row)] = len(nodes)
            nodes.append(point)
            coordinates.append((column, row))
    return nodes, coordinates, lookup


def _lattice_adjacency(
    coordinates: list[tuple[int, int]], lookup: dict[tuple[int, int], int]
) -> list[list[int]]:
    """Build every available orthogonal lattice connection."""
    adjacency = [[] for _ in coordinates]
    for index, (column, row) in enumerate(coordinates):
        for neighbor_coordinate in (
            (column - 1, row),
            (column + 1, row),
            (column, row - 1),
            (column, row + 1),
        ):
            neighbor = lookup.get(neighbor_coordinate)
            if neighbor is None:
                continue
            adjacency[index].append(neighbor)
    return adjacency


def _retain_envelope_nodes(
    width: int,
    height: int,
    seed: int,
    nodes: list[FloatPoint],
    coordinates: list[tuple[int, int]],
) -> tuple[list[FloatPoint], list[tuple[int, int]], dict[tuple[int, int], int]]:
    """Keep the largest connected lattice region inside the outer silhouette."""
    points_by_coordinate = dict(zip(coordinates, nodes))
    active = {
        coordinate
        for coordinate, point in points_by_coordinate.items()
        if _inside_envelope(width, height, seed, point[0], point[1])
    }
    unseen = set(active)
    largest: set[tuple[int, int]] = set()
    while unseen:
        start = unseen.pop()
        component = {start}
        stack = [start]
        while stack:
            column, row = stack.pop()
            for neighbor in (
                (column - 1, row),
                (column + 1, row),
                (column, row - 1),
                (column, row + 1),
            ):
                if neighbor in unseen:
                    unseen.remove(neighbor)
                    component.add(neighbor)
                    stack.append(neighbor)
        if len(component) > len(largest):
            largest = component
    kept_coordinates = [coordinate for coordinate in coordinates if coordinate in largest]
    kept_nodes = [points_by_coordinate[coordinate] for coordinate in kept_coordinates]
    lookup = {coordinate: index for index, coordinate in enumerate(kept_coordinates)}
    return kept_nodes, kept_coordinates, lookup


def _find_root(parents: list[int], node: int) -> int:
    """Return and compress one disjoint-set root."""
    while parents[node] != node:
        parents[node] = parents[parents[node]]
        node = parents[node]
    return node


def _edge_is_horizontal(
    nodes: list[FloatPoint], first: int, second: int
) -> bool:
    """Return whether one jittered lattice edge is primarily horizontal."""
    dx = abs(nodes[first][0] - nodes[second][0])
    dy = abs(nodes[first][1] - nodes[second][1])
    return dx >= dy


def _randomized_kruskal_tree(
    nodes: list[FloatPoint], adjacency: list[list[int]], rng: random.Random
) -> list[tuple[int, int]]:
    """Build one spanning tree with a moderate horizontal edge preference."""
    edges = {
        tuple(sorted((node, neighbor)))
        for node, neighbors in enumerate(adjacency)
        for neighbor in neighbors
    }
    weighted = [
        (
            rng.random()
            + (
                0.0
                if _edge_is_horizontal(nodes, first, second)
                else config.SKELETON_VERTICAL_EDGE_PENALTY
            ),
            first,
            second,
        )
        for first, second in edges
    ]
    parents = list(range(len(nodes)))
    result: list[tuple[int, int]] = []
    for _, first, second in sorted(weighted):
        first_root = _find_root(parents, first)
        second_root = _find_root(parents, second)
        if first_root == second_root:
            continue
        parents[second_root] = first_root
        result.append((first, second))
    return result


def _horizontal_ratio_deviation(ratio: float) -> float:
    """Return zero inside the desired moderate horizontal range."""
    if ratio < config.SKELETON_MIN_HORIZONTAL_RATIO:
        return config.SKELETON_MIN_HORIZONTAL_RATIO - ratio
    if ratio > config.SKELETON_MAX_HORIZONTAL_RATIO:
        return ratio - config.SKELETON_MAX_HORIZONTAL_RATIO
    return 0.0


def _maze_tree(
    nodes: list[FloatPoint], adjacency: list[list[int]], rng: random.Random
) -> list[tuple[int, int]]:
    """Choose a connected maze with short vertical chains and a long route."""
    candidates = [
        _randomized_kruskal_tree(nodes, adjacency, rng)
        for _ in range(config.SKELETON_TREE_ATTEMPTS)
    ]

    def shape_key(
        edges: list[tuple[int, int]],
    ) -> tuple[int, int, float, float, float]:
        """Rank construction defects before softer route preferences."""
        metrics = analyze_skeleton(nodes, edges)
        return (
            max(
                0,
                metrics.max_vertical_chain
                - config.SKELETON_MAX_VERTICAL_CHAIN,
            ),
            max(
                0,
                metrics.max_horizontal_chain
                - config.SKELETON_MAX_HORIZONTAL_CHAIN,
            ),
            _horizontal_ratio_deviation(metrics.horizontal_ratio),
            -metrics.backbone_ratio,
            metrics.leaf_ratio,
        )

    return min(candidates, key=shape_key)


def _distance_to_segment(
    point: FloatPoint, first: FloatPoint, second: FloatPoint
) -> float:
    """Return Euclidean distance from a point to one finite segment."""
    dx = second[0] - first[0]
    dy = second[1] - first[1]
    length_squared = dx * dx + dy * dy
    if length_squared == 0.0:
        return math.dist(point, first)
    projection = (
        (point[0] - first[0]) * dx + (point[1] - first[1]) * dy
    ) / length_squared
    projection = max(0.0, min(1.0, projection))
    closest = (first[0] + dx * projection, first[1] + dy * projection)
    return math.dist(point, closest)


def _curved_segments(
    seed: int, nodes: list[FloatPoint], edges: list[tuple[int, int]]
) -> list[tuple[FloatPoint, FloatPoint]]:
    """Bend graph edges so passages never expose the control lattice."""
    result: list[tuple[FloatPoint, FloatPoint]] = []
    for channel, (first_index, second_index) in enumerate(edges):
        first = nodes[first_index]
        second = nodes[second_index]
        dx = second[0] - first[0]
        dy = second[1] - first[1]
        length = max(1.0, math.hypot(dx, dy))
        normal = (-dy / length, dx / length)
        bend = (hash_unit(seed, first_index, second_index, channel) * 2.0 - 1.0) * min(
            3.4, length * 0.28
        )
        midpoint = (
            (first[0] + second[0]) * 0.5 + normal[0] * bend,
            (first[1] + second[1]) * 0.5 + normal[1] * bend,
        )
        result.extend(((first, midpoint), (midpoint, second)))
    return result


def _inside_envelope(
    width: int, height: int, seed: int, x: float, y: float
) -> bool:
    """Clip passages with four broad noisy profiles instead of a uniform border."""
    nx = x / max(1, width - 1)
    ny = y / max(1, height - 1)
    size_scale = 0.8 * math.sqrt(
        min(
            width / config.REFERENCE_INNER_WIDTH,
            height / config.REFERENCE_INNER_HEIGHT,
        )
    )
    vertical_scale = max(8.0, height * 0.42)
    horizontal_scale = max(8.0, width * 0.42)
    left = size_scale * (
        0.008
        + (value_noise(seed, 0.0, y, vertical_scale, 301) + 1.0) * 0.025
        + (value_noise(seed, 0.0, y, 9.0, 311) + 1.0) * 0.010
    )
    right = size_scale * (
        0.008
        + (value_noise(seed, width, y, vertical_scale, 302) + 1.0) * 0.025
        + (value_noise(seed, width, y, 9.0, 312) + 1.0) * 0.010
    )
    top = size_scale * (
        0.008
        + (value_noise(seed, x, 0.0, horizontal_scale, 303) + 1.0) * 0.025
        + (value_noise(seed, x, 0.0, 9.0, 313) + 1.0) * 0.010
    )
    bottom = size_scale * (
        0.008
        + (value_noise(seed, x, height, horizontal_scale, 304) + 1.0) * 0.025
        + (value_noise(seed, x, height, 9.0, 314) + 1.0) * 0.010
    )
    return left <= nx <= 1.0 - right and top <= ny <= 1.0 - bottom


def _rasterize(
    width: int,
    height: int,
    seed: int,
    nodes: list[FloatPoint],
    edges: list[tuple[int, int]],
    corridor_width_scale: float,
) -> list[list[bool]]:
    """Rasterize one domain-warped field around graph branches and junctions."""
    degrees = [0] * len(nodes)
    for first, second in edges:
        degrees[first] += 1
        degrees[second] += 1
    segments = _curved_segments(seed, nodes, edges)
    air = [[False] * width for _ in range(height)]
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            if not _inside_envelope(width, height, seed, x, y):
                continue
            point = (
                x + value_noise(seed, x, y, 15.0, 201) * 3.4,
                y + value_noise(seed, x, y, 17.0, 202) * 3.0,
            )
            edge_distance = min(
                _distance_to_segment(point, first, second)
                for first, second in segments
            )
            radius_noise = warped_fbm(seed ^ 0x534B454C, x, y)
            passage_radius = (
                config.CORRIDOR_RADIUS
                + radius_noise * config.CORRIDOR_RADIUS_VARIATION
            ) * corridor_width_scale
            open_cell = edge_distance <= passage_radius
            if not open_cell and edge_distance <= passage_radius + 1.0:
                open_cell = warped_fbm(seed ^ 0x504F5245, x, y) > 0.18
            for index, node in enumerate(nodes):
                pocket_radius = 3.25 if degrees[index] == 1 else 2.8
                if degrees[index] >= 3:
                    pocket_radius = 3.7
                if math.dist(point, node) <= (
                    pocket_radius + radius_noise * 0.45
                ) * corridor_width_scale:
                    open_cell = True
                    break
            air[y][x] = open_cell
    component = largest_component(air)
    return [[(x, y) in component for x in range(width)] for y in range(height)]


def generate_skeleton_air(
    width: int,
    height: int,
    seed: int,
    settings: config.TopologySettings,
) -> SkeletonAirResult:
    """Generate a long base graph and one optional qualified ring candidate."""
    rng = random.Random(seed ^ 0x4E4F495345)
    nodes, coordinates, lookup = _jittered_lattice(width, height, rng)
    nodes, coordinates, lookup = _retain_envelope_nodes(
        width, height, seed, nodes, coordinates
    )
    adjacency = _lattice_adjacency(coordinates, lookup)
    tree = _maze_tree(nodes, adjacency, rng)
    base_metrics = analyze_skeleton(nodes, tree)
    base_air = _rasterize(
        width,
        height,
        seed,
        nodes,
        tree,
        settings.corridor_width_scale,
    )
    loops = (
        select_loop_edges(nodes, adjacency, tree, 1)
        if should_add_loop(seed, settings.loop_density)
        else []
    )
    return SkeletonAirResult(base_air, base_metrics, nodes, tree, loops)


def rasterize_looped_skeleton(
    skeleton: SkeletonAirResult,
    width: int,
    height: int,
    seed: int,
    corridor_width_scale: float,
) -> tuple[list[list[bool]], SkeletonMetrics] | None:
    """Rasterize the optional ring graph only after its base cave qualifies."""
    if not skeleton.loop_edges:
        return None
    looped_air = _rasterize(
        width,
        height,
        seed,
        skeleton.nodes,
        skeleton.tree_edges + skeleton.loop_edges,
        corridor_width_scale,
    )
    return (
        looped_air,
        analyze_skeleton(
            skeleton.nodes,
            skeleton.tree_edges,
            skeleton.loop_edges,
        ),
    )
