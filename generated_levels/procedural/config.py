"""Tunable constants for procedural level generation."""

from __future__ import annotations

from dataclasses import dataclass

@dataclass(frozen=True)
class TopologySettings:
    """Control cave openness and measurable route structure."""

    loop_density: float = 0.25
    corridor_width_scale: float = 1.0
    min_route_detour_ratio: float = 1.45
    min_endpoint_detour_ratio: float = 1.9
    require_endpoint_occlusion: bool = True
    min_horizontal_surface_ratio: float = 0.85
    max_long_route_sightline_ratio: float = 0.03
    min_air_ratio: float = 0.43
    max_air_ratio: float = 0.61
    min_external_rock_ratio: float = 0.22
    max_external_rock_ratio: float = 0.30
    valid_candidate_target: int = 3


DEFAULT_TOPOLOGY = TopologySettings()

CELL_SIZE = 12
OUTER_X_PADDING = 2
REFERENCE_INNER_WIDTH = 82 - OUTER_X_PADDING * 2
REFERENCE_INNER_HEIGHT = 47 - OUTER_X_PADDING * 2
MIN_INNER_WIDTH = 42
MIN_INNER_HEIGHT = 25
MIN_WIDTH = MIN_INNER_WIDTH + OUTER_X_PADDING * 2
MIN_HEIGHT = MIN_INNER_HEIGHT + OUTER_X_PADDING * 2

# Cave skeleton and silhouette.
SKELETON_STEP_X = 10
SKELETON_STEP_Y = 9
SKELETON_TREE_ATTEMPTS = 64
SKELETON_VERTICAL_EDGE_PENALTY = 0.25
SKELETON_MIN_HORIZONTAL_RATIO = 0.60
SKELETON_MAX_HORIZONTAL_RATIO = 0.72
SKELETON_MAX_HORIZONTAL_CHAIN = 3
SKELETON_MAX_VERTICAL_CHAIN = 2
SKELETON_MIN_LOOP_LENGTH = 6
SKELETON_MAX_LOOP_LENGTH = 12
SKELETON_TARGET_LOOP_LENGTH = 9
CORRIDOR_RADIUS = 2.8
CORRIDOR_RADIUS_VARIATION = 0.8
TARGET_EXTERNAL_ROCK_RATIO = 0.26
TARGET_AIR_RATIO = 0.53
MIN_AIR_RATIO = 0.43
MAX_AIR_RATIO = 0.61
MIN_MAIN_COMPONENT_RATIO = 0.97
MAX_FLAT_SURFACE_RUN = 18
MAX_CENTRAL_OPEN_SPAN_RATIO = 0.55

# Secondary terrain features.
JUMP_THRU_AIR_PER_RUN = 290
JUMP_THRU_MIN_LENGTH = 2
JUMP_THRU_MAX_LENGTH = 5
JUMP_THRU_MIN_VERTICAL_STEP = 2
JUMP_THRU_MAX_UPWARD_STEP = 2
PLATFORM_CHAIN_MAX_RUNS = 3
PLATFORM_CHAIN_AIR_PER_CHAIN = 1700
HAZARD_AIR_RATIO = 0.045
HAZARD_MIN_RUN = 2
HAZARD_MAX_RUN = 8
HAZARD_SAFE_GAP = 7
HAZARD_CENTERED_CHANCE = 0.35
MIN_HAZARD_TARGET_RATIO = 0.45

# Entity pacing. Reference counts target an 82x47 level without its outer frame.
REFERENCE_LEVEL_AREA = REFERENCE_INNER_WIDTH * REFERENCE_INNER_HEIGHT
REFERENCE_BERRIES = 12
REFERENCE_ENEMIES = 11
BERRY_GROWTH_EXPONENT = 0.65
ENEMY_GROWTH_EXPONENT = 0.55
MIN_BERRIES = 4
MIN_ENEMIES = 3
BERRY_MIN_DISTANCE = 5
BERRY_MIN_PATH_DISTANCE = 10.0
BERRY_COVERAGE_PATH_DISTANCE = 18.0
BERRY_SPREAD_TOLERANCE = 2.0
BERRY_COUNT_VARIATION = 2
BERRY_GUARD_MIN_DISTANCE = 3.0
BERRY_GUARD_MAX_DISTANCE = 10.0
ENEMY_MIN_DISTANCE = 3
ENEMY_PATROL_SHORTFALL_COST = 3.0
ENEMY_ALTERNATIVE_TYPE_COST = 0.75
ENCOUNTER_ROUTE_ZONES = 10
ENCOUNTER_MAX_BONUS_RATIO = 0.30
CONTENT_LAYOUT_VARIANTS = 3

# Real gameplay physics, expressed in pixels.
PLAYER_WIDTH = 16
PLAYER_HEIGHT = 20
PLAYER_X_SPEED = 2
PLAYER_JUMP_RISE = 39
PLAYER_JUMP_SPAN = 48
PLAYER_FALL_SPEED = 6
SWORD_FLIGHT_SPEED = 6 * 60
SWORD_FLIGHT_RANGE = 3600
TELEPORT_SEARCH_RADIUS = 12

# Challenge star timing.
STAR_AIM_SECONDS = 1.0
THREE_STAR_TIME_FACTOR = 1.0
TWO_STAR_TIME_FACTOR = 2

# Collision/visual footprints relative to each runtime anchor, in pixels.
ENTITY_FOOTPRINTS = {
    "@": (-PLAYER_WIDTH // 2, -PLAYER_HEIGHT, PLAYER_WIDTH // 2, 0),
    "S": (-13, -12, 13, 0),
    "K": (-6, -24, 6, 0),
    "B": (-12, -35, 12, 0),
    "O": (-10, -18, 10, 19),
    "*": (-7, -8, 7, 8),
}
# Full-size jelly can overhang a safe ledge by two pixels; keep the old support comfort.
ENTITY_GROUND_SUPPORT = {"S": (-11, 11)}
ENTITY_PATROL_MARGIN = {
    "@": 24, "S": 24, "K": 36, "B": 48,
    "J": 48, "C": 48, "G": 72, "W": 72, "F": 0, "T": 48,
}

# Absolute, one-based game numbers; challenge file 01.json is game level 11.
CAMPAIGN_THEME_ENDS = ((20, "day"), (30, "evening"), (40, "night"))
ENEMY_SKINS = {
    "S": ("day", "evening", "night", "morning"),
    "K": ("day", "evening", "night", "morning"),
    "B": ("day", "evening", "night", "morning"),
    "G": ("day", "evening", "night", "morning"),
    "J": ("evening", "night", "morning"),
    "C": ("night",), "T": ("night",), "W": ("night",), "F": ("night",),
}
ENEMY_WEIGHTS_BY_THEME = {
    "day": (("S", .45), ("K", .25), ("B", .15), ("G", .15)),
    "evening": (("S", .20), ("K", .24), ("B", .12), ("J", .28), ("G", .16)),
    "night": (("S", .12), ("K", .10), ("B", .07), ("J", .14), ("C", .12),
              ("T", .14), ("G", .12), ("W", .10), ("F", .09)),
    "morning": (("S", .20), ("K", .22), ("B", .15), ("J", .25), ("G", .18)),
}
ENEMY_SYMBOLS = frozenset(symbol for upper in ENEMY_SKINS for symbol in (upper, upper.lower()))
ENEMY_ENCOUNTER_RADIUS = {"S": 4, "K": 5, "B": 6, "J": 6, "C": 8,
                          "T": 9, "G": 9, "W": 9, "F": 8}


def level_theme(game_level: int) -> str:
    """Resolve the campaign's absolute number using the runtime day boundaries."""
    if game_level < 1:
        raise ValueError("game_level must be a positive one-based game number")
    return next((theme for end, theme in CAMPAIGN_THEME_ENDS if game_level <= end), "morning")


def enemy_weights(game_level: int) -> tuple[tuple[str, float], ...]:
    """Select only families that have real artwork for this time of day."""
    theme = level_theme(game_level)
    return tuple((symbol, weight) for symbol, weight in ENEMY_WEIGHTS_BY_THEME[theme]
                 if theme in ENEMY_SKINS[symbol])

# Conservative body/art clearance at runtime scale, independent of animated masks.
ENTITY_FOOTPRINTS.update({
    "F":(-14,-40,50,0), "J":(-14,-40,18,0), "C":(-10,-20,10,0),
    "T":(-16,-15,16,15), "G":(-18,-38,18,0), "W":(-18,-48,18,0),
    "1":(-18,-38,18,0), "2":(-18,-38,18,0), "3":(-18,-38,18,0), "4":(-18,-38,18,0),
    "5":(-14,-40,18,0), "6":(-14,-40,18,0), "7":(-14,-40,18,0)
})
