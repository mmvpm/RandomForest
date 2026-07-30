"""Calculate challenge star thresholds from a simple ideal sword route."""

from __future__ import annotations

import heapq
import math
from dataclasses import dataclass

from . import config
from .level_format import decode_level


Point = tuple[int, int]


@dataclass(frozen=True)
class _PathSearch:
    """Store shortest grid distances and predecessors from one waypoint."""

    start: Point
    distances: dict[Point, float]
    previous: dict[Point, Point]

    def path_to(self, end: Point) -> tuple[Point, ...]:
        """Restore the shortest path to one reachable waypoint."""
        if end not in self.distances:
            return ()
        path = [end]
        while path[-1] != self.start:
            path.append(self.previous[path[-1]])
        path.reverse()
        return tuple(path)


def _entity_positions(level: dict[str, object], symbols: str) -> list[Point]:
    """Return entity coordinates matching any requested symbol."""
    rows = level["entities"]
    assert isinstance(rows, list)
    return [
        (x, y)
        for y, row in enumerate(rows)
        for x, symbol in enumerate(row)
        if symbol in symbols
    ]


def _route_cells(level: dict[str, object], waypoints: set[Point]) -> set[Point]:
    """Return collision-free maze cells plus occupied route endpoints."""
    rows = level["terrain"]
    assert isinstance(rows, list)
    return {
        (x, y)
        for y, row in enumerate(rows)
        for x, symbol in enumerate(row)
        if symbol in ".="
    } | waypoints


def _neighbors(point: Point, cells: set[Point]) -> list[tuple[Point, float]]:
    """Return eight-way neighbors without diagonal corner cutting."""
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


def _search(start: Point, cells: set[Point]) -> _PathSearch:
    """Build shortest maze paths from one route waypoint."""
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
    return _PathSearch(start, distances, previous)


def _line_clear(first: Point, second: Point, cells: set[Point]) -> bool:
    """Check a cell-center ray against solid maze cells."""
    dx = second[0] - first[0]
    dy = second[1] - first[1]
    steps = max(1, math.ceil(math.hypot(dx, dy) * 5))
    for step in range(steps + 1):
        ratio = step / steps
        x = math.floor(first[0] + 0.5 + dx * ratio)
        y = math.floor(first[1] + 0.5 + dy * ratio)
        if (x, y) not in cells:
            return False
    return True


def _simplify_path(path: tuple[Point, ...], cells: set[Point]) -> tuple[Point, ...]:
    """Collapse a grid path into the longest visible sword segments."""
    if len(path) <= 2:
        return path
    simplified = [path[0]]
    anchor = 0
    while anchor < len(path) - 1:
        target = len(path) - 1
        while target > anchor + 1 and not _line_clear(path[anchor], path[target], cells):
            target -= 1
        simplified.append(path[target])
        anchor = target
    return tuple(simplified)


def _greedy_route(level: dict[str, object]) -> tuple[tuple[Point, ...], ...]:
    """Visit the nearest remaining berry, then finish at the door."""
    semantic = decode_level(level) if "map" in level else level
    starts = _entity_positions(semantic, "@")
    doors = _entity_positions(semantic, "Oo")
    berries = set(_entity_positions(semantic, "*"))
    if len(starts) != 1 or len(doors) != 1:
        raise ValueError("Star timing requires one player and one door")

    waypoints = {starts[0], doors[0], *berries}
    cells = _route_cells(semantic, waypoints)
    current = starts[0]
    legs: list[tuple[Point, ...]] = []
    while berries:
        search = _search(current, cells)
        reachable = [berry for berry in berries if berry in search.distances]
        if not reachable:
            raise ValueError("A berry is unreachable for star timing")
        target = min(
            reachable,
            key=lambda point: (search.distances[point], point[1], point[0]),
        )
        legs.append(_simplify_path(search.path_to(target), cells))
        berries.remove(target)
        current = target

    final_search = _search(current, cells)
    door = doors[0]
    final_path = final_search.path_to(door)
    if not final_path:
        raise ValueError("The door is unreachable for star timing")
    legs.append(_simplify_path(final_path, cells))
    return tuple(legs)


def ideal_route_seconds(level: dict[str, object]) -> float:
    """Return sword flight and aiming time for the greedy maze route."""
    legs = _greedy_route(level)
    distance_cells = 0.0
    segment_count = 0
    for leg in legs:
        for first, second in zip(leg, leg[1:]):
            distance_cells += math.dist(first, second)
            segment_count += 1
    flight_seconds = (
        distance_cells * config.CELL_SIZE / config.SWORD_FLIGHT_SPEED
    )
    aiming_seconds = max(0, segment_count - 1) * config.STAR_AIM_SECONDS
    return flight_seconds + aiming_seconds


def calculate_star_times(level: dict[str, object]) -> dict[str, int]:
    """Return whole-second thresholds for three and two stars."""
    ideal_seconds = ideal_route_seconds(level)
    three_stars = max(
        1,
        math.ceil(ideal_seconds * config.THREE_STAR_TIME_FACTOR),
    )
    return {
        "three_stars": three_stars,
        "two_stars": three_stars * config.TWO_STAR_TIME_FACTOR,
    }
