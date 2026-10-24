"""Measure playable transitions between stable horizontal surfaces."""

from __future__ import annotations

import math
from dataclasses import dataclass

from . import config
from .features import _jump_trajectory_clear


Point = tuple[int, int]


@dataclass(frozen=True)
class SurfaceNode:
    """Describe one continuous floor or jump-through landing surface."""

    cells: tuple[Point, ...]
    kind: str

    @property
    def anchor(self) -> Point:
        """Return the central gameplay anchor of this surface."""
        return self.cells[len(self.cells) // 2]


@dataclass(frozen=True)
class AffordanceEdge:
    """Describe one physically sampled transition between two surfaces."""

    start: int
    end: int
    action: str
    hazard_cost: int


@dataclass(frozen=True)
class AffordanceGraph:
    """Contain stable surfaces and diagnostic gameplay transitions."""

    nodes: tuple[SurfaceNode, ...]
    edges: tuple[AffordanceEdge, ...]


@dataclass(frozen=True)
class AffordanceMetrics:
    """Summarize whether platforms add connected movement choices."""

    platform_runs: int
    useful_platform_runs: int
    isolated_platform_runs: int
    transition_count: int
    hazard_cost: int


def _surface_nodes(terrain: list[list[str]]) -> tuple[SurfaceNode, ...]:
    """Collect maximal exposed rock floors and jump-through runs."""
    nodes: list[SurfaceNode] = []
    for y, row in enumerate(terrain):
        x = 0
        while x < len(row):
            symbol = row[x]
            exposed_rock = symbol == "#" and y > 0 and terrain[y - 1][x] in ".="
            if symbol != "=" and not exposed_rock:
                x += 1
                continue
            kind = "platform" if symbol == "=" else "rock"
            cells: list[Point] = []
            while x < len(row):
                current = row[x]
                exposed = current == "#" and y > 0 and terrain[y - 1][x] in ".="
                if (kind == "platform" and current != "=") or (
                    kind == "rock" and not exposed
                ):
                    break
                cells.append((x, y))
                x += 1
            nodes.append(SurfaceNode(tuple(cells), kind))
    return tuple(nodes)


def _hazard_cost(hazards: list[list[str]], first: Point, second: Point) -> int:
    """Count nearby hazard samples along one coarse transition segment."""
    steps = max(1, round(math.dist(first, second)))
    cost = 0
    for step in range(steps + 1):
        ratio = step / steps
        x = round(first[0] + (second[0] - first[0]) * ratio)
        y = round(first[1] + (second[1] - first[1]) * ratio)
        cost += int(
            any(
                hazards[check_y][check_x] != "."
                for check_y in range(max(0, y - 1), min(len(hazards), y + 2))
                for check_x in range(max(0, x - 1), min(len(hazards[0]), x + 2))
            )
        )
    return cost


def _transition_clear(
    terrain: list[list[str]], start: SurfaceNode, end: SurfaceNode
) -> bool:
    """Try representative anchors so long surfaces do not hide valid edges."""
    start_points = {start.cells[0], start.anchor, start.cells[-1]}
    end_points = {end.cells[0], end.anchor, end.cells[-1]}
    return any(
        _jump_trajectory_clear(terrain, start_point, end_point)
        for start_point in start_points
        for end_point in end_points
    )


def build_affordance_graph(
    terrain: list[list[str]] | list[str],
    hazards: list[list[str]] | list[str] | None = None,
) -> AffordanceGraph:
    """Build a diagnostic graph using the runtime jump trajectory sampler."""
    grid = [list(row) for row in terrain]
    hazard_grid = (
        [list(row) for row in hazards]
        if hazards is not None
        else [["."] * len(grid[0]) for _ in grid]
    )
    nodes = _surface_nodes(grid)
    edges: list[AffordanceEdge] = []
    maximum_span = math.ceil(config.PLAYER_JUMP_SPAN / config.CELL_SIZE) + 3
    maximum_drop = math.ceil(config.PLAYER_FALL_SPEED * 10 / config.CELL_SIZE)
    for start_index, start in enumerate(nodes):
        for end_index, end in enumerate(nodes):
            if start_index == end_index:
                continue
            if start.kind == end.kind == "rock":
                continue
            dx = abs(start.anchor[0] - end.anchor[0])
            dy = end.anchor[1] - start.anchor[1]
            if dx > maximum_span or dy > maximum_drop:
                continue
            if not _transition_clear(grid, start, end):
                continue
            action = "fall" if dy >= 2 else "jump"
            edges.append(
                AffordanceEdge(
                    start=start_index,
                    end=end_index,
                    action=action,
                    hazard_cost=_hazard_cost(hazard_grid, start.anchor, end.anchor),
                )
            )
    return AffordanceGraph(nodes, tuple(edges))


def _connected_to_rock(
    graph: AffordanceGraph,
    terrain: list[list[str]] | None = None,
) -> set[int]:
    """Return surfaces connected physically or laterally to natural rock."""
    connected = {
        index for index, node in enumerate(graph.nodes) if node.kind == "rock"
    }
    if terrain is not None:
        connected.update(
            index
            for index, node in enumerate(graph.nodes)
            if node.kind == "platform"
            and (
                (
                    node.cells[0][0] > 0
                    and terrain[node.cells[0][1]][node.cells[0][0] - 1] == "#"
                )
                or (
                    node.cells[-1][0] + 1 < len(terrain[0])
                    and terrain[node.cells[-1][1]][node.cells[-1][0] + 1] == "#"
                )
            )
        )
    changed = True
    while changed:
        changed = False
        for edge in graph.edges:
            if edge.start in connected and edge.end not in connected:
                connected.add(edge.end)
                changed = True
            if edge.end in connected and edge.start not in connected:
                connected.add(edge.start)
                changed = True
    return connected


def platform_runs_are_supported(terrain: list[list[str]] | list[str]) -> bool:
    """Return whether every floating platform belongs to a rock-linked chain."""
    grid = [list(row) for row in terrain]
    graph = build_affordance_graph(grid)
    connected = _connected_to_rock(graph, grid)
    return all(
        node.kind != "platform" or index in connected
        for index, node in enumerate(graph.nodes)
    )


def analyze_affordances(
    terrain: list[list[str]] | list[str],
    hazards: list[list[str]] | list[str] | None = None,
) -> AffordanceMetrics:
    """Measure useful platform connectivity without imposing a hard route model."""
    graph = build_affordance_graph(terrain, hazards)
    connected = _connected_to_rock(graph)
    degrees = {index: 0 for index in range(len(graph.nodes))}
    for edge in graph.edges:
        degrees[edge.start] += 1
        degrees[edge.end] += 1
    platform_indices = [
        index for index, node in enumerate(graph.nodes) if node.kind == "platform"
    ]
    useful = sum(
        index in connected and degrees[index] >= 2 for index in platform_indices
    )
    isolated = sum(index not in connected for index in platform_indices)
    return AffordanceMetrics(
        platform_runs=len(platform_indices),
        useful_platform_runs=useful,
        isolated_platform_runs=isolated,
        transition_count=len(graph.edges),
        hazard_cost=sum(edge.hazard_cost for edge in graph.edges),
    )
