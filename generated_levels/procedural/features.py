"""Place jump-through platforms and physically supported spike runs."""

from __future__ import annotations

import random
import math
from collections.abc import Sequence
from dataclasses import dataclass

from . import config


@dataclass(frozen=True)
class _SurfaceRun:
    """Describe one continuous exposed rock surface."""

    cells: tuple[tuple[int, int], ...]
    direction: str


def _is_air(terrain: list[list[str]], x: int, y: int) -> bool:
    """Return whether a terrain coordinate is playable air."""
    return 0 <= y < len(terrain) and 0 <= x < len(terrain[0]) and terrain[y][x] == "."


def _clear_vertical(terrain: list[list[str]], x: int, y: int) -> bool:
    """Return whether a jump-through cell has useful space on both sides."""
    return all(_is_air(terrain, x, check_y) for check_y in range(y - 3, y + 3))


def _jump_through_candidates(terrain: list[list[str]]) -> list[tuple[tuple[int, int], ...]]:
    """Find bridges and wall-anchored ledges that do not float arbitrarily."""
    height = len(terrain)
    width = len(terrain[0])
    candidates: set[tuple[tuple[int, int], ...]] = set()
    for y in range(4, height - 3):
        for length in range(config.JUMP_THRU_MIN_LENGTH, config.JUMP_THRU_MAX_LENGTH + 1):
            for start in range(2, width - length - 2):
                cells = tuple((x, y) for x in range(start, start + length))
                if not all(_clear_vertical(terrain, x, y) for x, _ in cells):
                    continue
                left_anchor = terrain[y][start - 1] == "#"
                right_anchor = terrain[y][start + length] == "#"
                bridge = left_anchor and right_anchor
                cantilever = left_anchor != right_anchor and length <= 4
                if (bridge or cantilever) and _has_jump_affordance(terrain, cells):
                    candidates.add(cells)
    return list(candidates)


def _has_jump_affordance(
    terrain: list[list[str]], cells: tuple[tuple[int, int], ...]
) -> bool:
    """Require exact takeoff-to-platform and platform-to-landing trajectories."""
    center_x = round(sum(x for x, _ in cells) / len(cells))
    platform_y = cells[0][1]
    span = math.ceil(config.PLAYER_JUMP_SPAN / config.CELL_SIZE) + 2
    rise = math.floor(config.PLAYER_JUMP_RISE / config.CELL_SIZE)
    fall_buffer = math.ceil(config.PLAYER_FALL_SPEED / config.CELL_SIZE)
    surfaces: list[tuple[int, int]] = []
    for y in range(max(2, platform_y - rise), min(len(terrain) - 1, platform_y + rise + 2)):
        first_x = max(1, center_x - span - fall_buffer)
        last_x = min(len(terrain[0]) - 1, center_x + span + fall_buffer + 1)
        for x in range(first_x, last_x):
            if terrain[y][x] == "#" and terrain[y - 1][x] == ".":
                surfaces.append((x, y))
    platform = (center_x, platform_y)
    takeoffs = [
        surface for surface in surfaces if _jump_trajectory_clear(terrain, surface, platform)
    ]
    landings = [
        surface for surface in surfaces if _jump_trajectory_clear(terrain, platform, surface)
    ]
    return any(
        takeoff != landing and math.dist(takeoff, landing) >= 2.0
        for takeoff in takeoffs
        for landing in landings
    )


def _player_clear_at(terrain: list[list[str]], pixel_x: float, pixel_y: float) -> bool:
    """Check the player's exact pixel footprint at one trajectory sample."""
    left, top, right, bottom = config.ENTITY_FOOTPRINTS["@"]
    first_x = math.floor((pixel_x + left) / config.CELL_SIZE)
    last_x = math.floor((pixel_x + right - 1e-6) / config.CELL_SIZE)
    first_y = math.floor((pixel_y + top) / config.CELL_SIZE)
    last_y = math.floor((pixel_y + bottom - 1e-6) / config.CELL_SIZE)
    if first_x < 0 or first_y < 0 or last_x >= len(terrain[0]) or last_y >= len(terrain):
        return False
    return all(
        terrain[y][x] != "#"
        for y in range(first_y, last_y + 1)
        for x in range(first_x, last_x + 1)
    )


def _jump_trajectory_clear(
    terrain: list[list[str]], start: tuple[int, int], target: tuple[int, int]
) -> bool:
    """Simulate the real discrete jump and sweep the player footprint along it."""
    start_x = start[0] * config.CELL_SIZE
    start_y = start[1] * config.CELL_SIZE
    target_x = target[0] * config.CELL_SIZE
    target_y = target[1] * config.CELL_SIZE
    if start_y - target_y > config.PLAYER_JUMP_RISE:
        return False
    vertical_positions = [float(start_y)]
    velocity_y = -6.5
    landing_frame = 0
    for frame in range(1, 61):
        velocity_y = min(config.PLAYER_FALL_SPEED, velocity_y + 0.5)
        next_y = vertical_positions[-1] + velocity_y
        vertical_positions.append(next_y)
        if velocity_y >= 0 and vertical_positions[-2] <= target_y <= next_y:
            landing_frame = frame
            break
    if landing_frame == 0:
        return False
    velocity_x = (target_x - start_x) / landing_frame
    if abs(velocity_x) > config.PLAYER_X_SPEED:
        return False
    if start_y == target_y and abs(target_x - start_x) > config.PLAYER_JUMP_SPAN:
        return False
    return all(
        _player_clear_at(
            terrain,
            start_x + velocity_x * frame,
            vertical_positions[frame],
        )
        for frame in range(1, landing_frame + 1)
    )


def place_jump_throughs(terrain: list[list[str]], air_count: int, seed: int) -> None:
    """Place a restrained set of naturally anchored one-way platforms."""
    rng = random.Random(seed ^ 0x4A554D50)
    candidates = _jump_through_candidates(terrain)
    rng.shuffle(candidates)
    target_runs = max(2, round(air_count / config.JUMP_THRU_AIR_PER_RUN))
    occupied: set[tuple[int, int]] = set()
    placed = 0
    for cells in candidates:
        if placed >= target_runs:
            break
        if any(
            abs(x - ox) <= 2
            and abs(y - oy) < config.JUMP_THRU_MIN_VERTICAL_STEP
            for x, y in cells
            for ox, oy in occupied
        ):
            continue
        for x, y in cells:
            terrain[y][x] = "="
            occupied.add((x, y))
        placed += 1


def _surface_cell_valid(
    terrain: list[list[str]], x: int, y: int, direction: str
) -> bool:
    """Check air, tip clearance, and the visible-rock base of one spike."""
    if not _is_air(terrain, x, y):
        return False
    if direction == "up":
        return terrain[y + 1][x] == "#" and _is_air(terrain, x, y - 1)
    if direction == "down":
        return terrain[y - 1][x] == "#" and _is_air(terrain, x, y + 1)
    if direction == "left":
        return terrain[y][x + 1] == "#" and _is_air(terrain, x - 1, y)
    return terrain[y][x - 1] == "#" and _is_air(terrain, x + 1, y)


def _collect_surface_runs(terrain: list[list[str]]) -> list[_SurfaceRun]:
    """Collect horizontal and vertical runs with consistent spike direction."""
    height = len(terrain)
    width = len(terrain[0])
    runs: list[_SurfaceRun] = []
    for direction in ("up", "down"):
        for y in range(2, height - 2):
            current: list[tuple[int, int]] = []
            for x in range(2, width - 2):
                if _surface_cell_valid(terrain, x, y, direction):
                    current.append((x, y))
                else:
                    if len(current) >= config.HAZARD_MIN_RUN:
                        runs.append(_SurfaceRun(tuple(current), direction))
                    current = []
            if len(current) >= config.HAZARD_MIN_RUN:
                runs.append(_SurfaceRun(tuple(current), direction))
    for direction in ("left", "right"):
        for x in range(2, width - 2):
            current = []
            for y in range(2, height - 2):
                if _surface_cell_valid(terrain, x, y, direction):
                    current.append((x, y))
                else:
                    if len(current) >= config.HAZARD_MIN_RUN:
                        runs.append(_SurfaceRun(tuple(current), direction))
                    current = []
            if len(current) >= config.HAZARD_MIN_RUN:
                runs.append(_SurfaceRun(tuple(current), direction))
    return runs


def spike_run_has_side_backing(
    terrain: Sequence[Sequence[str]],
    cells: Sequence[tuple[int, int]],
    direction: str,
) -> bool:
    """Require black mass beside the run and one cell behind both ends."""
    if not cells:
        return False
    first = cells[0]
    last = cells[-1]
    if direction in ("up", "down"):
        side_cells = ((first[0] - 1, first[1]), (last[0] + 1, last[1]))
        backing = (0, 1 if direction == "up" else -1)
    else:
        side_cells = ((first[0], first[1] - 1), (last[0], last[1] + 1))
        backing = (1 if direction == "left" else -1, 0)
    required = {
        (x, y)
        for side_x, side_y in side_cells
        for x, y in (
            (side_x, side_y),
            (side_x + backing[0], side_y + backing[1]),
        )
    }
    return all(
        0 <= y < len(terrain)
        and 0 <= x < len(terrain[0])
        and terrain[y][x] in "#X"
        for x, y in required
    )


def _side_anchored(terrain: list[list[str]], run: _SurfaceRun) -> bool:
    """Require two-cell-deep black sides around one spike run."""
    return spike_run_has_side_backing(terrain, run.cells, run.direction)


def _hazard_symbol(direction: str, centered: bool) -> str:
    """Return the hazard symbol for one direction and brush phase."""
    aligned = {"up": "U", "down": "D", "left": "L", "right": "R"}
    centered_symbols = {"up": "^", "down": "v", "left": "<", "right": ">"}
    return centered_symbols[direction] if centered else aligned[direction]


def _spike_rear_cells(x: int, y: int, symbol: str) -> set[tuple[int, int]]:
    """Return the solid and black base sections on the 6-pixel grid."""
    if symbol == "U":
        return {
            (x * 2 + cross, y * 2 + offset)
            for cross in range(2)
            for offset in (2, 3)
        }
    if symbol == "^":
        return {
            (x * 2 + cross, y * 2 + offset)
            for cross in range(2)
            for offset in (1, 2)
        }
    if symbol == "D":
        return {
            (x * 2 + cross, y * 2 + offset)
            for cross in range(2)
            for offset in (-1, -2)
        }
    if symbol == "v":
        return {
            (x * 2 + cross, y * 2 + offset)
            for cross in range(2)
            for offset in (0, -1)
        }
    if symbol == "L":
        return {
            (x * 2 + offset, y * 2 + cross)
            for cross in range(2)
            for offset in (2, 3)
        }
    if symbol == "<":
        return {
            (x * 2 + offset, y * 2 + cross)
            for cross in range(2)
            for offset in (1, 2)
        }
    if symbol == "R":
        return {
            (x * 2 + offset, y * 2 + cross)
            for cross in range(2)
            for offset in (-1, -2)
        }
    return {
        (x * 2 + offset, y * 2 + cross)
        for cross in range(2)
        for offset in (0, -1)
    }


def _spike_run_rear_overlaps(
    hazards: list[list[str]],
    cells: tuple[tuple[int, int], ...],
    symbol: str,
) -> bool:
    """Reject a new run whose black rear overlaps another run."""
    new_rear = set().union(
        *(_spike_rear_cells(x, y, symbol) for x, y in cells)
    )
    for y, row in enumerate(hazards):
        for x, existing_symbol in enumerate(row):
            if (
                existing_symbol != "."
                and new_rear & _spike_rear_cells(x, y, existing_symbol)
            ):
                return True
    return False


def spike_has_deep_backing(
    terrain: Sequence[Sequence[str]],
    hazards: Sequence[Sequence[str]],
    x: int,
    y: int,
    symbol: str,
) -> bool:
    """Require mass or an opposing spike two cells behind one spike."""
    if symbol in "^U":
        dx, dy, opposing_symbols = 0, 2, "vD"
    elif symbol in "vD":
        dx, dy, opposing_symbols = 0, -2, "^U"
    elif symbol in "<L":
        dx, dy, opposing_symbols = 2, 0, ">R"
    else:
        dx, dy, opposing_symbols = -2, 0, "<L"
    backing_x = x + dx
    backing_y = y + dy
    if not (0 <= backing_y < len(terrain) and 0 <= backing_x < len(terrain[0])):
        return False
    if terrain[backing_y][backing_x] in "#X":
        return True
    return hazards[backing_y][backing_x] in opposing_symbols


def _remove_shallow_spike_runs(
    terrain: list[list[str]],
    hazards: list[list[str]],
    placed_runs: list[tuple[tuple[tuple[int, int], ...], str]],
) -> None:
    """Remove complete spike runs that end in air behind their rock base."""
    active_runs = list(placed_runs)
    while True:
        shallow_runs = [
            run
            for run in active_runs
            if not all(
                spike_has_deep_backing(terrain, hazards, x, y, run[1])
                for x, y in run[0]
            )
        ]
        if not shallow_runs:
            return
        for cells, _ in shallow_runs:
            for x, y in cells:
                hazards[y][x] = "."
        active_runs = [run for run in active_runs if run not in shallow_runs]


def _route_metrics(route: tuple[tuple[int, int], ...]) -> list[tuple[tuple[int, int], float]]:
    """Attach normalized arclength to main-route control points."""
    distances = [0.0]
    for first, second in zip(route, route[1:]):
        distances.append(distances[-1] + math.dist(first, second))
    total = max(1.0, distances[-1])
    return [(point, distance / total) for point, distance in zip(route, distances)]


def _run_stage(run: _SurfaceRun, route: list[tuple[tuple[int, int], float]]) -> float:
    """Project a surface run onto the closest main-route stage."""
    center = run.cells[len(run.cells) // 2]
    _, stage = min(route, key=lambda item: math.dist(center, item[0]))
    return stage


def place_hazards(
    terrain: list[list[str]],
    air_count: int,
    route: tuple[tuple[int, int], ...],
    seed: int,
) -> list[list[str]]:
    """Place supported spike runs while preserving safe gaps on every surface."""
    height = len(terrain)
    width = len(terrain[0])
    hazards = [["."] * width for _ in range(height)]
    rng = random.Random(seed ^ 0x5350494B45)
    runs = [
        run
        for run in _collect_surface_runs(terrain)
        if len(run.cells) <= config.HAZARD_MAX_RUN
        and _side_anchored(terrain, run)
    ]
    route_metrics = _route_metrics(route)
    target_cells = round(air_count * config.HAZARD_AIR_RATIO)
    occupied: set[tuple[int, int]] = set()
    placed_runs: list[tuple[tuple[tuple[int, int], ...], str]] = []
    placed_cells = 0
    remaining = list(runs)
    run_index = 0
    while remaining and placed_cells < target_cells:
        desired_stage = ((run_index % 8) + 0.5) / 8.0
        run = min(
            remaining,
            key=lambda candidate: abs(_run_stage(candidate, route_metrics) - desired_stage)
            + rng.random() * 0.12,
        )
        remaining.remove(run)
        run_index += 1
        if placed_cells >= target_cells:
            break
        cells = run.cells
        if any(
            math.dist((x, y), endpoint) < config.HAZARD_SAFE_GAP
            for x, y in cells
            for endpoint in (route[0], route[-1])
        ):
            continue
        if any(
            abs(x - ox) <= 1 and abs(y - oy) <= 1
            for x, y in cells
            for ox, oy in occupied
        ):
            continue
        symbol = _hazard_symbol(
            run.direction, rng.random() < config.HAZARD_CENTERED_CHANCE
        )
        if _spike_run_rear_overlaps(hazards, cells, symbol):
            continue
        for x, y in cells:
            hazards[y][x] = symbol
            occupied.add((x, y))
        placed_runs.append((cells, symbol))
        placed_cells += len(cells)
    _remove_shallow_spike_runs(terrain, hazards, placed_runs)
    return hazards
