"""Place player, exit, rewards, and enemies using entity footprints."""

from __future__ import annotations

import math
import random

from . import config
from .berry_distribution import BerryCandidate, select_berry_candidates
from .encounters import (
    EncounterZone,
    build_encounter_zones,
    candidate_suitability,
    encounter_enemy_target,
    ordered_encounter_zones,
)
from .placement import (
    berry_has_safe_landing,
    ground_support_bounds,
    pixel_footprint_clear,
)
from .topology import build_navigation_search, navigation_distances


Point = tuple[int, int]
RouteMetric = tuple[Point, float]


def _hazard_near(hazards: list[list[str]], x: int, y: int, radius: int) -> bool:
    """Return whether a hazard occupies the requested square neighborhood."""
    height = len(hazards)
    width = len(hazards[0])
    return any(
        hazards[ny][nx] != "."
        for ny in range(max(0, y - radius), min(height, y + radius + 1))
        for nx in range(max(0, x - radius), min(width, x + radius + 1))
    )


def _ground_candidate(
    terrain: list[list[str]], hazards: list[list[str]], x: int, y: int, symbol: str
) -> bool:
    """Check hard footprint support, headroom, and hazard clearance."""
    left, right = ground_support_bounds(x, symbol)
    if left < 1 or right >= len(terrain[0]) - 1 or y < 2:
        return False
    for floor_x in range(left, right):
        if terrain[y][floor_x] != "#":
            return False
    return _footprint_clear(terrain, x, y, symbol) and not _hazard_near(
        hazards, x, y - 1, 2
    )


def _has_patrol_comfort(terrain: list[list[str]], point: Point, symbol: str) -> bool:
    """Return whether a safe anchor also has the preferred patrol width."""
    x, y = point
    left_px, _, right_px, _ = config.ENTITY_FOOTPRINTS[symbol]
    floor_width = math.ceil(
        (right_px - left_px + config.ENTITY_PATROL_MARGIN[symbol])
        / config.CELL_SIZE
    )
    left = x - (floor_width - 1) // 2
    right = left + floor_width
    return left >= 1 and right < len(terrain[0]) - 1 and all(
        terrain[y][floor_x] == "#" for floor_x in range(left, right)
    )


def _footprint_clear(
    terrain: list[list[str]], x: int, y: int, symbol: str
) -> bool:
    """Check the exact pixel footprint against semantic terrain cells."""
    return _pixel_footprint_clear(
        terrain, x * config.CELL_SIZE, y * config.CELL_SIZE, symbol
    )


def _pixel_footprint_clear(
    terrain: list[list[str]], anchor_x: float, anchor_y: float, symbol: str
) -> bool:
    """Check one entity footprint at an arbitrary pixel anchor."""
    return pixel_footprint_clear(terrain, anchor_x, anchor_y, symbol)


def _sword_ray_clear(terrain: list[list[str]], start: Point, target: Point) -> bool:
    """Check a local unobstructed sword ray from the route toward a reward."""
    distance_pixels = _distance(start, target) * config.CELL_SIZE
    if distance_pixels > config.SWORD_FLIGHT_RANGE:
        return False
    steps = max(1, math.ceil(distance_pixels / 6))
    for step in range(1, steps):
        t = step / steps
        x = round(start[0] + (target[0] - start[0]) * t)
        y = round(start[1] + (target[1] - start[1]) * t)
        if terrain[y][x] == "#":
            return False
    return True


def _ground_candidates(
    terrain: list[list[str]],
    hazards: list[list[str]],
    symbol: str,
    require_comfort: bool = False,
) -> list[Point]:
    """Return hard-safe anchors, optionally retaining conservative comfort."""
    return [
        (x, y)
        for y in range(2, len(terrain) - 1)
        for x in range(2, len(terrain[0]) - 2)
        if _ground_candidate(terrain, hazards, x, y, symbol)
        and (not require_comfort or _has_patrol_comfort(terrain, (x, y), symbol))
    ]


def _distance(first: Point, second: Point) -> float:
    """Return Euclidean distance in semantic cells."""
    return math.hypot(first[0] - second[0], first[1] - second[1])


def _route_metrics(route: tuple[Point, ...]) -> list[RouteMetric]:
    """Attach normalized graph arclength to every main-route control point."""
    distances = [0.0]
    for first, second in zip(route, route[1:]):
        distances.append(distances[-1] + _distance(first, second))
    total = max(1.0, distances[-1])
    return [(point, distance / total) for point, distance in zip(route, distances)]


def _route_stage(point: Point, route: list[RouteMetric]) -> float:
    """Project one content point onto the nearest main-route stage."""
    _, stage = min(route, key=lambda item: _distance(point, item[0]))
    return stage


def _choose_start_and_door_floor(
    terrain: list[list[str]],
    player_candidates: list[Point],
    door_candidates: list[Point],
    canvas_width: int,
    topology: config.TopologySettings,
    rng: random.Random,
) -> tuple[Point, Point, tuple[Point, ...]]:
    """Choose endpoints with a concrete winding and occluded route."""
    if not player_candidates or not door_candidates:
        raise ValueError("The cave has too few safe player platforms")
    player_pool = _sample_entity_candidates(player_candidates, 64)
    door_pool = _sample_entity_candidates(door_candidates, 64)
    choices: list[tuple[float, Point, Point, tuple[Point, ...]]] = []
    for start in player_pool:
        search = build_navigation_search(terrain, start)
        for door_floor in door_pool:
            door = _door_anchor(terrain, door_floor)
            if door is None or abs(start[0] - door[0]) < canvas_width * 0.45:
                continue
            path = search.path_to(door)
            if not path:
                continue
            path_length = search.distances[door]
            direct_distance = _distance(start, door)
            detour_ratio = path_length / max(1.0, direct_distance)
            if detour_ratio < topology.min_endpoint_detour_ratio:
                continue
            if topology.require_endpoint_occlusion and search.line_clear_to(door):
                continue
            score = path_length + detour_ratio * 12.0 + direct_distance * 0.1
            choices.append((score, start, door_floor, path))
    if not choices:
        raise ValueError("The cave has no winding player-to-door route")
    best_score = max(choice[0] for choice in choices)
    strong = [choice for choice in choices if choice[0] >= best_score - 2.0]
    _, start, door_floor, selected_route = rng.choice(strong)
    return start, door_floor, selected_route


def _sample_entity_candidates(candidates: list[Point], limit: int) -> list[Point]:
    """Keep a deterministic spatial sample for endpoint path searches."""
    ordered = sorted(candidates, key=lambda point: (point[0], point[1]))
    if len(ordered) <= limit:
        return ordered
    return [
        ordered[round(index * (len(ordered) - 1) / (limit - 1))]
        for index in range(limit)
    ]


def _door_anchor(terrain: list[list[str]], floor: Point) -> Point | None:
    """Return a portal anchor two cells above its supporting floor."""
    x, floor_y = floor
    anchor_y = floor_y - 2
    if anchor_y < 2:
        return None
    return (x, anchor_y) if _footprint_clear(terrain, x, anchor_y, "O") else None


def _reserved(point: Point, occupied: list[tuple[Point, int]]) -> bool:
    """Return whether a candidate intersects an existing reserved radius."""
    return any(_distance(point, other) < radius for other, radius in occupied)


def scaled_entity_count(
    reference: int, level_area: int, exponent: float, minimum: int
) -> int:
    """Scale one content count sub-linearly from the reference level area."""
    scale = max(0.1, level_area / config.REFERENCE_LEVEL_AREA)
    return max(minimum, round(reference * scale**exponent))


def enemy_target(level_area: int) -> int:
    """Return the scaled total enemy target for one level area."""
    return scaled_entity_count(
        config.REFERENCE_ENEMIES,
        level_area,
        config.ENEMY_GROWTH_EXPONENT,
        config.MIN_ENEMIES,
    )


def _weighted_enemy(rng: random.Random) -> str:
    """Choose a preferred enemy type from the configured weights."""
    value = rng.random()
    total = 0.0
    for symbol, weight in config.ENEMY_WEIGHTS:
        total += weight
        if value <= total:
            return symbol
    return config.ENEMY_WEIGHTS[-1][0]


def _choose_enemy_candidate(
    terrain: list[list[str]],
    candidates_by_type: dict[str, list[Point]],
    occupied: list[tuple[Point, int]],
    route: list[RouteMetric],
    zone: EncounterZone,
    preferred_type: str,
    rng: random.Random,
) -> tuple[str, Point] | None:
    """Choose the best type and natural anchor for one encounter slot."""
    choices: list[tuple[float, str, Point]] = []
    for symbol, candidates in candidates_by_type.items():
        type_cost = (
            0.0
            if symbol == preferred_type
            else config.ENEMY_ALTERNATIVE_TYPE_COST
        )
        for candidate in candidates:
            if _reserved(candidate, occupied):
                continue
            suitability = candidate_suitability(
                terrain,
                symbol,
                candidate,
                _route_stage(candidate, route),
                zone,
            )
            choices.append(
                (suitability + type_cost + rng.random() * 0.08, symbol, candidate)
            )
    if not choices:
        return None
    _, symbol, point = min(choices, key=lambda choice: choice[0])
    return symbol, point


def _berry_candidates(
    terrain: list[list[str]],
    hazards: list[list[str]],
    occupied: list[tuple[Point, int]],
    route: list[RouteMetric],
    enemies: list[Point],
) -> list[BerryCandidate]:
    """Build collectible candidates with graph access and enemy context."""
    height = len(terrain)
    width = len(terrain[0])
    navigation = build_navigation_search(terrain, route[0][0])
    route_points = tuple(point for point, _ in route if point in navigation.cells)
    route_depths = navigation_distances(navigation.cells, route_points)
    enemy_anchors = [
        min(navigation.cells, key=lambda cell: _distance(enemy, cell))
        for enemy in enemies
    ]
    enemy_depths = [
        route_depths.get(anchor, 0.0) for anchor in enemy_anchors
    ]
    enemy_distances = [
        navigation_distances(navigation.cells, [anchor])
        for anchor in enemy_anchors
    ]
    result: list[BerryCandidate] = []
    for y in range(2, height - 2):
        for x in range(2, width - 2):
            if terrain[y][x] != "." or hazards[y][x] != ".":
                continue
            if _reserved((x, y), occupied):
                continue
            if not _footprint_clear(terrain, x, y, "*"):
                continue
            if not berry_has_safe_landing(terrain, hazards, (x, y)):
                continue
            wall_count = sum(
                terrain[ny][nx] in "#X"
                for ny in range(max(0, y - 3), min(height, y + 4))
                for nx in range(max(0, x - 3), min(width, x + 4))
            )
            risk_penalty = 5.0 if _hazard_near(hazards, x, y, 4) else 0.0
            point = (x, y)
            nearest_route = min(route, key=lambda item: _distance(point, item[0]))[0]
            walk_anchors = [
                (landing_x, landing_y)
                for landing_y in range(y, y + 3)
                for landing_x in range(x - 1, x + 2)
                if (landing_x, landing_y) in navigation.distances
                and not _hazard_near(hazards, landing_x, landing_y, 1)
            ]
            sword_accessible = _sword_ray_clear(terrain, nearest_route, point)
            if not walk_anchors and not sword_accessible:
                continue
            sword_bonus = 4.0 if sword_accessible else 0.0
            access_point = (
                min(
                    walk_anchors,
                    key=lambda anchor: (
                        _distance(anchor, point),
                        navigation.distances[anchor],
                    ),
                )
                if walk_anchors
                else nearest_route
            )
            branch_depth = route_depths.get(access_point, 0.0)
            guarded_enemies = frozenset(
                enemy_index
                for enemy_index, distances in enumerate(enemy_distances)
                if config.BERRY_GUARD_MIN_DISTANCE
                <= distances.get(access_point, math.inf)
                <= config.BERRY_GUARD_MAX_DISTANCE
                and branch_depth > enemy_depths[enemy_index]
            )
            result.append(
                BerryCandidate(
                    point=point,
                    access_point=access_point,
                    quality=wall_count * 0.35 - risk_penalty + sword_bonus,
                    branch_depth=branch_depth,
                    guarded_enemies=guarded_enemies,
                )
            )
    return result


def place_entities(
    terrain: list[list[str]],
    hazards: list[list[str]],
    route: tuple[Point, ...],
    seed: int,
    topology: config.TopologySettings = config.DEFAULT_TOPOLOGY,
) -> list[list[str]]:
    """Place all entities while respecting type-specific physical space."""
    height = len(terrain)
    width = len(terrain[0])
    entities = [["."] * width for _ in range(height)]
    rng = random.Random(seed ^ 0x454E54495459)
    player_floors = _ground_candidates(terrain, hazards, "@", require_comfort=True)
    door_floors = [floor for floor in player_floors if _door_anchor(terrain, floor)]
    start_floor, door_floor, selected_route = _choose_start_and_door_floor(
        terrain,
        player_floors,
        door_floors,
        width,
        topology,
        rng,
    )
    route_metrics = _route_metrics(selected_route)
    door = _door_anchor(terrain, door_floor)
    assert door is not None
    entities[start_floor[1]][start_floor[0]] = "@"
    entities[door[1]][door[0]] = rng.choice(("O", "o"))
    safe_radius = math.ceil(
        (config.PLAYER_WIDTH / 2 + config.TELEPORT_SEARCH_RADIUS)
        / config.CELL_SIZE
    ) + 2
    occupied: list[tuple[Point, int]] = [
        (start_floor, safe_radius),
        (door, safe_radius),
    ]

    level_area = width * height
    zones = build_encounter_zones(terrain, route_metrics, seed)
    target = encounter_enemy_target(enemy_target(level_area), zones)
    encounter_schedule = ordered_encounter_zones(zones, target)
    enemy_candidates = {
        symbol: _ground_candidates(terrain, hazards, symbol)
        for symbol in ("S", "K", "B")
    }
    for candidates in enemy_candidates.values():
        rng.shuffle(candidates)
    placed_enemies = 0
    enemy_points: list[Point] = []
    for enemy_index in range(target):
        preferred_type = _weighted_enemy(rng)
        zone = encounter_schedule[enemy_index]
        choice = _choose_enemy_candidate(
            terrain,
            enemy_candidates,
            occupied,
            route_metrics,
            zone,
            preferred_type,
            rng,
        )
        if choice is None:
            continue
        symbol, point = choice
        enemy_candidates[symbol].remove(point)
        nearest_index = min(
            range(len(route_metrics)),
            key=lambda index: _distance(point, route_metrics[index][0]),
        )
        facing_index = min(nearest_index + 1, len(route_metrics) - 1)
        facing_x = route_metrics[facing_index][0][0]
        facing_symbol = symbol.lower() if facing_x < point[0] else symbol
        entities[point[1]][point[0]] = facing_symbol
        occupied.append((point, config.ENEMY_MIN_DISTANCE))
        enemy_points.append(point)
        placed_enemies += 1
    if placed_enemies != target:
        raise ValueError("The cave cannot support the requested encounter pacing")

    berry_target = scaled_entity_count(
        config.REFERENCE_BERRIES,
        level_area,
        config.BERRY_GROWTH_EXPONENT,
        config.MIN_BERRIES,
    )
    berry_candidates = _berry_candidates(
        terrain,
        hazards,
        occupied,
        route_metrics,
        enemy_points,
    )
    berry_navigation = build_navigation_search(terrain, route_metrics[0][0])
    selected_berries = select_berry_candidates(
        berry_candidates,
        berry_target,
        lambda start: navigation_distances(berry_navigation.cells, [start]),
        rng,
    )
    for candidate in selected_berries:
        point = candidate.point
        entities[point[1]][point[0]] = "*"
        occupied.append((point, config.BERRY_MIN_DISTANCE))
    return entities
