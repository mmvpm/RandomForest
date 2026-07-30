"""Measure player-sized cave topology and recover its main route."""

from __future__ import annotations

import heapq
import math
from dataclasses import dataclass

from . import config


Point = tuple[int, int]


@dataclass(frozen=True)
class TopologyMetrics:
    """Describe navigation structure after terrain has been rasterized."""

    route: tuple[Point, ...]
    component_ratio: float
    detour_ratio: float
    horizontal_surface_ratio: float
    long_sightline_ratio: float
    air_ratio: float


@dataclass(frozen=True)
class NavigationSearch:
    """Hold reusable shortest paths from one player-clearance anchor."""

    start: Point
    cells: frozenset[Point]
    distances: dict[Point, float]
    previous: dict[Point, Point]

    def path_to(self, end: Point) -> tuple[Point, ...]:
        """Restore the shortest path to end, or return an empty path."""
        if end not in self.distances:
            return ()
        return _restore_path(self.start, end, self.previous)

    def line_clear_to(self, end: Point) -> bool:
        """Return whether end has a direct player-clearance sightline."""
        return end in self.distances and _line_clear(self.start, end, self.cells)


def _player_clear(terrain: list[list[str]], x: int, y: int) -> bool:
    """Return whether the player footprint fits at one semantic anchor."""
    left, top, right, bottom = config.ENTITY_FOOTPRINTS["@"]
    anchor_x = x * config.CELL_SIZE
    anchor_y = y * config.CELL_SIZE
    first_x = math.floor((anchor_x + left) / config.CELL_SIZE)
    last_x = math.floor((anchor_x + right - 1e-6) / config.CELL_SIZE)
    first_y = math.floor((anchor_y + top) / config.CELL_SIZE)
    last_y = math.floor((anchor_y + bottom - 1e-6) / config.CELL_SIZE)
    if first_x < 0 or first_y < 0:
        return False
    if last_x >= len(terrain[0]) or last_y >= len(terrain):
        return False
    return all(
        terrain[check_y][check_x] in ".="
        for check_y in range(first_y, last_y + 1)
        for check_x in range(first_x, last_x + 1)
    )


def _clearance_cells(terrain: list[list[str]]) -> set[Point]:
    """Build the set of player-sized anchors in playable air."""
    return {
        (x, y)
        for y in range(len(terrain))
        for x in range(len(terrain[0]))
        if _player_clear(terrain, x, y)
    }


def _spawn_floor_cells(terrain: list[list[str]], cells: set[Point]) -> set[Point]:
    """Return clearance anchors with enough continuous floor for the player."""
    footprint_width = config.PLAYER_WIDTH + config.ENTITY_PATROL_MARGIN["@"]
    floor_width = math.ceil(footprint_width / config.CELL_SIZE)
    result: set[Point] = set()
    for x, y in cells:
        left = x - (floor_width - 1) // 2
        right = left + floor_width
        if left < 0 or right > len(terrain[0]):
            continue
        if all(terrain[y][floor_x] == "#" for floor_x in range(left, right)):
            result.add((x, y))
    return result


def _neighbors(point: Point, cells: set[Point]) -> list[tuple[Point, float]]:
    """Return clearance neighbors without diagonal corner cutting."""
    x, y = point
    result: list[tuple[Point, float]] = []
    for dx, dy in (
        (-1, 0),
        (1, 0),
        (0, -1),
        (0, 1),
        (-1, -1),
        (-1, 1),
        (1, -1),
        (1, 1),
    ):
        neighbor = (x + dx, y + dy)
        if neighbor not in cells:
            continue
        if dx and dy and ((x + dx, y) not in cells or (x, y + dy) not in cells):
            continue
        result.append((neighbor, math.hypot(dx, dy)))
    return result


def _largest_component(cells: set[Point]) -> set[Point]:
    """Return the largest connected player-clearance component."""
    unseen = set(cells)
    largest: set[Point] = set()
    while unseen:
        start = unseen.pop()
        component = {start}
        stack = [start]
        while stack:
            point = stack.pop()
            for neighbor, _ in _neighbors(point, cells):
                if neighbor in unseen:
                    unseen.remove(neighbor)
                    component.add(neighbor)
                    stack.append(neighbor)
        if len(component) > len(largest):
            largest = component
    return largest


def _paths_from(
    start: Point, cells: set[Point]
) -> tuple[dict[Point, float], dict[Point, Point]]:
    """Find shortest clearance paths from one anchor."""
    distances = {start: 0.0}
    previous: dict[Point, Point] = {}
    queue: list[tuple[float, Point]] = [(0.0, start)]
    while queue:
        distance, point = heapq.heappop(queue)
        if distance != distances[point]:
            continue
        for neighbor, cost in _neighbors(point, cells):
            candidate = distance + cost
            if candidate >= distances.get(neighbor, math.inf):
                continue
            distances[neighbor] = candidate
            previous[neighbor] = point
            heapq.heappush(queue, (candidate, neighbor))
    return distances, previous


def navigation_distances(
    cells: set[Point] | frozenset[Point],
    starts: set[Point] | frozenset[Point] | tuple[Point, ...] | list[Point],
) -> dict[Point, float]:
    """Measure shortest navigation distance from the nearest supplied start."""
    navigation_cells = set(cells)
    valid_starts = [start for start in starts if start in navigation_cells]
    distances = {start: 0.0 for start in valid_starts}
    queue: list[tuple[float, Point]] = [(0.0, start) for start in valid_starts]
    heapq.heapify(queue)
    while queue:
        distance, point = heapq.heappop(queue)
        if distance != distances[point]:
            continue
        for neighbor, cost in _neighbors(point, navigation_cells):
            candidate = distance + cost
            if candidate >= distances.get(neighbor, math.inf):
                continue
            distances[neighbor] = candidate
            heapq.heappush(queue, (candidate, neighbor))
    return distances


def _restore_path(start: Point, end: Point, previous: dict[Point, Point]) -> tuple[Point, ...]:
    """Restore one previously measured shortest path."""
    path = [end]
    while path[-1] != start:
        path.append(previous[path[-1]])
    path.reverse()
    return tuple(path)


def _sample_band(points: list[Point], count: int) -> list[Point]:
    """Select deterministic representatives from a vertical boundary band."""
    ordered = sorted(points, key=lambda point: (point[1], point[0]))
    if len(ordered) <= count:
        return ordered
    return [
        ordered[round(index * (len(ordered) - 1) / (count - 1))]
        for index in range(count)
    ]


def _main_route(
    cells: set[Point], width: int, endpoint_cells: set[Point]
) -> tuple[tuple[Point, ...], float]:
    """Find the strongest shortest route spanning left and right cave zones."""
    if not cells:
        return (), 0.0
    endpoints = endpoint_cells & cells
    if len(endpoints) < 2:
        endpoints = cells
    minimum_x = min(x for x, _ in endpoints)
    maximum_x = max(x for x, _ in endpoints)
    band_width = max(3, round(width * 0.12))
    left = [point for point in endpoints if point[0] <= minimum_x + band_width]
    right = {point for point in endpoints if point[0] >= maximum_x - band_width}
    best: tuple[float, float, Point, Point, dict[Point, Point]] | None = None
    for start in _sample_band(left, 5):
        distances, previous = _paths_from(start, cells)
        reachable = [point for point in right if point in distances]
        if not reachable:
            continue
        end = max(reachable, key=lambda point: distances[point])
        length = distances[end]
        direct = math.dist(start, end)
        detour = length / max(1.0, direct)
        candidate = (length, detour, start, end, previous)
        if best is None or candidate[:2] > best[:2]:
            best = candidate
    if best is None:
        return (), 0.0
    length, detour, start, end, previous = best
    return _restore_path(start, end, previous), detour


def _surface_ratio(terrain: list[list[str]]) -> float:
    """Compare exposed horizontal rock surfaces with vertical walls."""
    height = len(terrain)
    width = len(terrain[0])
    horizontal = 0
    vertical = 0
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            if terrain[y][x] != "#":
                continue
            horizontal += int(terrain[y - 1][x] in ".=")
            horizontal += int(terrain[y + 1][x] in ".=")
            vertical += int(terrain[y][x - 1] in ".=")
            vertical += int(terrain[y][x + 1] in ".=")
    return horizontal / max(1, vertical)


def _line_clear(
    first: Point, second: Point, cells: set[Point] | frozenset[Point]
) -> bool:
    """Check a sampled straight teleport line inside player clearance."""
    steps = max(abs(second[0] - first[0]), abs(second[1] - first[1]))
    if steps <= 1:
        return True
    return all(
        (
            round(first[0] + (second[0] - first[0]) * step / steps),
            round(first[1] + (second[1] - first[1]) * step / steps),
        )
        in cells
        for step in range(1, steps)
    )


def _long_sightline_ratio(route: tuple[Point, ...], cells: set[Point]) -> float:
    """Measure direct shortcuts between distant stages of the main route."""
    if len(route) < 8:
        return 1.0
    sample_count = min(32, len(route))
    samples = [
        route[round(index * (len(route) - 1) / (sample_count - 1))]
        for index in range(sample_count)
    ]
    separation = max(2, math.ceil(sample_count * 0.25))
    pairs = [
        (first, second)
        for first in range(sample_count)
        for second in range(first + separation, sample_count)
    ]
    visible = sum(_line_clear(samples[first], samples[second], cells) for first, second in pairs)
    return visible / max(1, len(pairs))


def analyze_topology(terrain: list[list[str]] | list[str]) -> TopologyMetrics:
    """Measure route and silhouette quality for one semantic terrain grid."""
    grid = [list(row) for row in terrain]
    cells = _clearance_cells(grid)
    component = _largest_component(cells)
    grounded = _spawn_floor_cells(grid, component)
    route, detour_ratio = _main_route(component, len(grid[0]), grounded)
    return TopologyMetrics(
        route=route,
        component_ratio=len(component) / max(1, len(cells)),
        detour_ratio=detour_ratio,
        horizontal_surface_ratio=_surface_ratio(grid),
        long_sightline_ratio=_long_sightline_ratio(route, component),
        air_ratio=sum(cell in ".=" for row in grid for cell in row)
        / (len(grid) * len(grid[0])),
    )


def clearance_component_ratio(terrain: list[list[str]] | list[str]) -> float:
    """Return the share of player-clearance anchors in the main component."""
    grid = [list(row) for row in terrain]
    cells = _clearance_cells(grid)
    return len(_largest_component(cells)) / max(1, len(cells))


def build_navigation_search(
    terrain: list[list[str]] | list[str], start: Point
) -> NavigationSearch:
    """Build reusable player-clearance paths from one concrete endpoint."""
    grid = [list(row) for row in terrain]
    cells = _clearance_cells(grid)
    if start not in cells:
        return NavigationSearch(start, frozenset(cells), {}, {})
    distances, previous = _paths_from(start, cells)
    return NavigationSearch(start, frozenset(cells), distances, previous)


def topology_is_qualified(
    metrics: TopologyMetrics, settings: config.TopologySettings
) -> bool:
    """Return whether measured terrain satisfies requested topology gates."""
    return (
        bool(metrics.route)
        and metrics.component_ratio >= config.MIN_MAIN_COMPONENT_RATIO
        and metrics.detour_ratio >= settings.min_route_detour_ratio
        and metrics.horizontal_surface_ratio >= settings.min_horizontal_surface_ratio
        and metrics.long_sightline_ratio <= settings.max_long_route_sightline_ratio
        and settings.min_air_ratio <= metrics.air_ratio <= settings.max_air_ratio
    )
