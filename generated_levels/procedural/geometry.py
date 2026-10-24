"""Small grid and deterministic-noise helpers."""

from __future__ import annotations

import math
from collections import deque
from collections.abc import Iterable


Point = tuple[int, int]
FloatPoint = tuple[float, float]


def stable_hash(seed: int, x: int, y: int, channel: int = 0) -> int:
    """Return a stable unsigned hash for one coordinate and channel."""
    value = seed & 0xFFFFFFFFFFFFFFFF
    value ^= (x + 0x9E3779B9) * 0x85EBCA6B
    value ^= (y + 0xC2B2AE35) * 0x27D4EB2F
    value ^= (channel + 1) * 0x165667B1
    value ^= value >> 30
    value *= 0xBF58476D1CE4E5B9
    value ^= value >> 27
    value *= 0x94D049BB133111EB
    value ^= value >> 31
    return value & 0xFFFFFFFFFFFFFFFF


def hash_unit(seed: int, x: int, y: int, channel: int = 0) -> float:
    """Return a stable coordinate value in the inclusive range 0..1."""
    return stable_hash(seed, x, y, channel) / 0xFFFFFFFFFFFFFFFF


def _smooth(value: float) -> float:
    """Interpolate value-noise coordinates without sharp lattice seams."""
    return value * value * (3.0 - 2.0 * value)


def value_noise(seed: int, x: float, y: float, scale: float, channel: int) -> float:
    """Sample smooth dependency-free value noise in the range -1..1."""
    sx = x / scale
    sy = y / scale
    x0 = math.floor(sx)
    y0 = math.floor(sy)
    tx = _smooth(sx - x0)
    ty = _smooth(sy - y0)
    v00 = hash_unit(seed, x0, y0, channel)
    v10 = hash_unit(seed, x0 + 1, y0, channel)
    v01 = hash_unit(seed, x0, y0 + 1, channel)
    v11 = hash_unit(seed, x0 + 1, y0 + 1, channel)
    top = v00 + (v10 - v00) * tx
    bottom = v01 + (v11 - v01) * tx
    return (top + (bottom - top) * ty) * 2.0 - 1.0


def warped_fbm(seed: int, x: float, y: float) -> float:
    """Sample three-octave noise after a low-frequency domain warp."""
    warp_x = value_noise(seed, x, y, 19.0, 41) * 4.0
    warp_y = value_noise(seed, x, y, 23.0, 42) * 4.0
    x += warp_x
    y += warp_y
    return (
        value_noise(seed, x, y, 13.0, 43) * 0.56
        + value_noise(seed, x, y, 6.5, 44) * 0.29
        + value_noise(seed, x, y, 3.25, 45) * 0.15
    )


def neighbors4(x: int, y: int) -> Iterable[Point]:
    """Yield orthogonal grid neighbors."""
    yield x - 1, y
    yield x + 1, y
    yield x, y - 1
    yield x, y + 1


def largest_component(grid: list[list[bool]]) -> set[Point]:
    """Return the largest orthogonally connected true component."""
    height = len(grid)
    width = len(grid[0])
    unseen = {(x, y) for y in range(height) for x in range(width) if grid[y][x]}
    largest: set[Point] = set()
    while unseen:
        start = unseen.pop()
        component = {start}
        queue = deque([start])
        while queue:
            x, y = queue.popleft()
            for neighbor in neighbors4(x, y):
                nx, ny = neighbor
                if 0 <= nx < width and 0 <= ny < height and neighbor in unseen:
                    unseen.remove(neighbor)
                    component.add(neighbor)
                    queue.append(neighbor)
        if len(component) > len(largest):
            largest = component
    return largest


def distance_squared(first: FloatPoint, second: FloatPoint) -> float:
    """Return squared Euclidean distance between two points."""
    return (first[0] - second[0]) ** 2 + (first[1] - second[1]) ** 2
