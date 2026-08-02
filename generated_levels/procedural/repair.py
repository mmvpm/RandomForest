"""Apply tightly budgeted local terrain repairs for encounter placement."""

from __future__ import annotations

import math
from dataclasses import dataclass

from . import config
from .placement import ground_support_bounds, pixel_footprint_clear


Point = tuple[int, int]


@dataclass
class RepairBudget:
    """Track the explicit cost of local collision edits."""

    limit: int
    spent: int = 0

    @property
    def remaining(self) -> int:
        """Return the number of edits still allowed."""
        return max(0, self.limit - self.spent)

    def consume(self, amount: int) -> None:
        """Record one accepted repair cost."""
        self.spent += amount


def _air_component_count(terrain: list[list[str]]) -> int:
    """Count four-connected playable-air components."""
    unseen = {
        (x, y)
        for y, row in enumerate(terrain)
        for x, cell in enumerate(row)
        if cell in ".="
    }
    count = 0
    while unseen:
        count += 1
        stack = [unseen.pop()]
        while stack:
            x, y = stack.pop()
            for point in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if point in unseen:
                    unseen.remove(point)
                    stack.append(point)
    return count


def _repairable_support(
    terrain: list[list[str]],
    hazards: list[list[str]],
    point: Point,
    symbol: str,
    protected: set[Point],
) -> Point | None:
    """Return the sole safe missing support cell for one entity anchor."""
    x, y = point
    if y <= 1 or y >= len(terrain) - 1:
        return None
    first_x, last_x = ground_support_bounds(x, symbol)
    if first_x < 1 or last_x >= len(terrain[0]) - 1:
        return None
    missing = [
        (floor_x, y)
        for floor_x in range(first_x, last_x)
        if terrain[y][floor_x] != "#"
    ]
    if len(missing) != 1:
        return None
    repair = missing[0]
    repair_x, repair_y = repair
    if terrain[repair_y][repair_x] != "." or hazards[repair_y][repair_x] != ".":
        return None
    if any(math.dist(repair, route_point) < 2.0 for route_point in protected):
        return None
    horizontally_attached = any(
        terrain[repair_y][neighbor_x] == "#"
        for neighbor_x in (repair_x - 1, repair_x + 1)
    )
    backed = terrain[repair_y + 1][repair_x] in "#X"
    if not horizontally_attached or not backed:
        return None
    return repair


def repair_ground_support_near(
    terrain: list[list[str]],
    hazards: list[list[str]],
    symbol: str,
    center: Point,
    protected_route: tuple[Point, ...],
    occupied: list[tuple[Point, int]],
    budget: RepairBudget,
    radius: int = 5,
) -> Point | None:
    """Add at most one local support cell without changing air connectivity."""
    if budget.remaining <= 0:
        return None
    component_count = _air_component_count(terrain)
    candidates = sorted(
        (
            (x, y)
            for y in range(
                max(2, center[1] - radius),
                min(len(terrain) - 1, center[1] + radius + 1),
            )
            for x in range(
                max(2, center[0] - radius),
                min(len(terrain[0]) - 2, center[0] + radius + 1),
            )
        ),
        key=lambda point: math.dist(point, center),
    )
    protected = set(protected_route)
    for point in candidates:
        if any(
            math.dist(point, other) < reserved_radius
            for other, reserved_radius in occupied
        ):
            continue
        if any(
            hazards[check_y][check_x] != "."
            for check_y in range(max(0, point[1] - 2), min(len(hazards), point[1] + 1))
            for check_x in range(max(0, point[0] - 2), min(len(hazards[0]), point[0] + 3))
        ):
            continue
        repair = _repairable_support(
            terrain, hazards, point, symbol, protected
        )
        if repair is None:
            continue
        repair_x, repair_y = repair
        terrain[repair_y][repair_x] = "#"
        if _air_component_count(terrain) != component_count or not pixel_footprint_clear(
            terrain,
            point[0] * config.CELL_SIZE,
            point[1] * config.CELL_SIZE,
            symbol,
        ):
            terrain[repair_y][repair_x] = "."
            continue
        budget.consume(1)
        return point
    return None
