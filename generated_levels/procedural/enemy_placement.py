"""Check the space an encounter needs beyond its stationary body."""

from . import config
from .placement import pixel_footprint_clear


def ground_encounter_fits(terrain: list[list[str]], x: int, y: int, symbol: str) -> bool:
    """Keep large attackers out of tiny shelves and jumps out of low tunnels."""
    if symbol in "SKB":
        return True
    if symbol == "F":
        # The jaw reaches farther than the rosette; it can face either approach.
        return all(pixel_footprint_clear(terrain, (x + dx) * 12, y * 12, symbol)
                   for dx in (-3, 0))
    margin = {"J": 2, "C": 2, "G": 3, "W": 3, "F": 1}[symbol]
    # Both facing directions must remain usable after patrol or player approach.
    if symbol == "J" and y < 5:
        return False
    return all(pixel_footprint_clear(terrain, (x + dx) * 12, y * 12, symbol)
               for dx in range(-margin, margin + 1)) and (
        symbol != "J" or all(terrain[y - 5][cx] == "." for cx in range(x - 2, x + 3))
    )


def bat_candidates(terrain: list[list[str]], hazards: list[list[str]]) -> list[tuple[int, int]]:
    """Find real ceiling perches over open chambers with room to dive and retreat."""
    result = []
    for y in range(4, len(terrain) - 6):
        for x in range(4, len(terrain[0]) - 4):
            if not all(terrain[y - 3][cx] == "#" for cx in range(x - 1, x + 2)):
                continue
            if not all(terrain[cy][cx] == "." and hazards[cy][cx] == "."
                       for cy in range(y - 2, y + 4) for cx in range(x - 3, x + 4)):
                continue
            # Perch marker is 24 px below the ceiling; runtime finds and attaches to it.
            if pixel_footprint_clear(terrain, x * config.CELL_SIZE, y * config.CELL_SIZE, "T"):
                result.append((x, y))
    return result
