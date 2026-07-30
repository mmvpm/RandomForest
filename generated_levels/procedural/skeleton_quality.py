"""Measure tree shape and choose meaningful local graph cycles."""

from __future__ import annotations

import math
import random
from dataclasses import dataclass

from . import config
from .geometry import FloatPoint


Edge = tuple[int, int]


@dataclass(frozen=True)
class SkeletonMetrics:
    """Describe the route coverage and branching of one cave skeleton."""

    backbone_ratio: float
    leaf_ratio: float
    loop_count: int
    cycle_coverage_ratio: float
    horizontal_ratio: float = 0.0
    max_horizontal_chain: int = 0
    max_vertical_chain: int = 0


def _edge(first: int, second: int) -> Edge:
    """Return one graph edge in stable undirected order."""
    return tuple(sorted((first, second)))


def _weighted_adjacency(
    nodes: list[FloatPoint], edges: list[Edge]
) -> list[list[tuple[int, float]]]:
    """Build weighted adjacency for one geometric graph."""
    adjacency: list[list[tuple[int, float]]] = [[] for _ in nodes]
    for first, second in edges:
        weight = math.dist(nodes[first], nodes[second])
        adjacency[first].append((second, weight))
        adjacency[second].append((first, weight))
    return adjacency


def _is_horizontal(nodes: list[FloatPoint], edge: Edge) -> bool:
    """Return whether one jittered lattice edge is primarily horizontal."""
    first, second = edge
    dx = abs(nodes[first][0] - nodes[second][0])
    dy = abs(nodes[first][1] - nodes[second][1])
    return dx >= dy


def _maximum_direction_chain(
    nodes: list[FloatPoint],
    edges: list[Edge],
    horizontal: bool,
) -> int:
    """Return the longest connected run made from one edge orientation."""
    adjacency: list[list[int]] = [[] for _ in nodes]
    for first, second in edges:
        if _is_horizontal(nodes, (first, second)) != horizontal:
            continue
        adjacency[first].append(second)
        adjacency[second].append(first)
    unseen = {index for index, neighbors in enumerate(adjacency) if neighbors}
    longest = 0
    while unseen:
        start = unseen.pop()
        component = {start}
        stack = [start]
        while stack:
            node = stack.pop()
            for neighbor in adjacency[node]:
                if neighbor not in component:
                    component.add(neighbor)
                    unseen.discard(neighbor)
                    stack.append(neighbor)
        longest = max(longest, len(component) - 1)
    return longest


def _tree_distances(
    start: int, adjacency: list[list[tuple[int, float]]]
) -> tuple[dict[int, float], dict[int, int]]:
    """Measure all paths in a tree from one node."""
    distances = {start: 0.0}
    previous: dict[int, int] = {}
    stack = [start]
    while stack:
        node = stack.pop()
        for neighbor, weight in adjacency[node]:
            if neighbor in distances:
                continue
            distances[neighbor] = distances[node] + weight
            previous[neighbor] = node
            stack.append(neighbor)
    return distances, previous


def _backbone_edges(nodes: list[FloatPoint], tree_edges: list[Edge]) -> set[Edge]:
    """Return the weighted tree diameter as stable edges."""
    adjacency = _weighted_adjacency(nodes, tree_edges)
    first_distances, _ = _tree_distances(0, adjacency)
    first = max(first_distances, key=first_distances.get)
    second_distances, previous = _tree_distances(first, adjacency)
    second = max(second_distances, key=second_distances.get)
    result: set[Edge] = set()
    node = second
    while node != first:
        parent = previous[node]
        result.add(_edge(node, parent))
        node = parent
    return result


def _tree_path_edges(
    first: int, second: int, adjacency: list[list[tuple[int, float]]]
) -> set[Edge]:
    """Return the unique tree path between two nodes."""
    _, previous = _tree_distances(first, adjacency)
    result: set[Edge] = set()
    node = second
    while node != first:
        parent = previous[node]
        result.add(_edge(node, parent))
        node = parent
    return result


def analyze_skeleton(
    nodes: list[FloatPoint],
    tree_edges: list[Edge],
    loop_edges: list[Edge] | None = None,
) -> SkeletonMetrics:
    """Measure backbone coverage, tree leaves, and cycle coverage."""
    loops = loop_edges or []
    backbone = _backbone_edges(nodes, tree_edges)
    tree_length = sum(math.dist(nodes[first], nodes[second]) for first, second in tree_edges)
    backbone_length = sum(
        math.dist(nodes[first], nodes[second]) for first, second in backbone
    )
    degrees = [0] * len(nodes)
    for first, second in tree_edges:
        degrees[first] += 1
        degrees[second] += 1
    adjacency = _weighted_adjacency(nodes, tree_edges)
    cycle_edges = {
        edge
        for first, second in loops
        for edge in _tree_path_edges(first, second, adjacency)
    }
    return SkeletonMetrics(
        backbone_ratio=backbone_length / max(1.0, tree_length),
        leaf_ratio=sum(degree == 1 for degree in degrees) / max(1, len(nodes)),
        loop_count=len(loops),
        cycle_coverage_ratio=len(cycle_edges) / max(1, len(tree_edges)),
        horizontal_ratio=sum(
            _is_horizontal(nodes, edge) for edge in tree_edges
        )
        / max(1, len(tree_edges)),
        max_horizontal_chain=_maximum_direction_chain(
            nodes,
            tree_edges,
            horizontal=True,
        ),
        max_vertical_chain=_maximum_direction_chain(
            nodes,
            tree_edges,
            horizontal=False,
        ),
    )


def should_add_loop(seed: int, loop_density: float) -> bool:
    """Choose a deterministic minority of seeds for one loop attempt."""
    chance = max(0.0, min(1.0, loop_density))
    return random.Random(seed ^ 0x4C4F4F50).random() < chance


def select_loop_edges(
    nodes: list[FloatPoint],
    lattice_adjacency: list[list[int]],
    tree_edges: list[Edge],
    count: int,
) -> list[Edge]:
    """Choose long, mostly separate cycles that avoid the main backbone."""
    existing = {_edge(*edge) for edge in tree_edges}
    candidates = {
        _edge(node, neighbor)
        for node, neighbors in enumerate(lattice_adjacency)
        for neighbor in neighbors
    } - existing
    tree_adjacency = _weighted_adjacency(nodes, tree_edges)
    backbone = _backbone_edges(nodes, tree_edges)
    paths = {
        edge: _tree_path_edges(edge[0], edge[1], tree_adjacency)
        for edge in candidates
    }
    selected: list[Edge] = []
    covered: set[Edge] = set()
    for _ in range(count):
        usable = [
            edge
            for edge in candidates - set(selected)
            if config.SKELETON_MIN_LOOP_LENGTH
            <= len(paths[edge])
            <= config.SKELETON_MAX_LOOP_LENGTH
        ]
        if not usable:
            break
        choice = min(
            usable,
            key=lambda edge: (
                not _is_horizontal(nodes, edge),
                len(paths[edge] & backbone) / len(paths[edge]),
                len(paths[edge] & covered),
                abs(len(paths[edge]) - config.SKELETON_TARGET_LOOP_LENGTH),
                -len(paths[edge] - covered),
                edge,
            ),
        )
        selected.append(choice)
        covered.update(paths[choice])
    return selected
