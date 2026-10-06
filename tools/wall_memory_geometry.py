"""Read authored and generated room terrain for wall placement verification."""

import json
import re
from pathlib import Path

import numpy as np


PROJECT = Path(__file__).resolve().parents[1] / "RandomForest"
ROOMS = [f"rTutorial{i:02}" for i in range(1, 7)] + [f"rLevel{i:02}" for i in range(1, 5)]


def read_yy(path):
    """Read GameMaker JSON with its optional trailing commas."""
    return json.loads(re.sub(r",\s*([}\]])", r"\1", path.read_text()))


def expand_tiles(tiles):
    """Expand the room's run/literal tile stream."""
    if "TileSerialiseData" in tiles:
        return tiles["TileSerialiseData"]
    result, cursor = [], 0
    data = tiles["TileCompressedData"]
    while cursor < len(data):
        count = data[cursor]
        cursor += 1
        if count < 0:
            result.extend([data[cursor]] * -count)
            cursor += 1
        else:
            result.extend(data[cursor:cursor + count])
            cursor += count
    return result


def room_geometry(number, path):
    """Return exact black fill and safe standing positions without changing terrain."""
    if number > 10:
        data = json.loads(path.read_text())
        grid = data["map"]
        width, height = data["width"] * 12, data["height"] * 12
        spawn = next((x * 12, (y + 1) * 12) for y, row in enumerate(grid)
                     for x, symbol in enumerate(row) if symbol == "@")
    else:
        data = read_yy(path)
        width, height = data["roomSettings"]["Width"], data["roomSettings"]["Height"]
        tiles = next(layer["tiles"] for layer in data["layers"] if layer["name"] == "Platforms")
        cells = expand_tiles(tiles)
        columns = tiles["SerialiseWidth"]
        grid = ["".join("X" if (value & 0xFFFFF) == 10 else "#" if value & 0xFFFFF else "."
                        for value in cells[y * columns:(y + 1) * columns])
                for y in range(tiles["SerialiseHeight"])]
        spawn = next((item["x"], item["y"]) for layer in data["layers"]
                     for item in layer.get("instances", []) if item["objectId"]["name"] == "oPlayer")
    mask = np.zeros((height, width), dtype=bool)
    for y, row in enumerate(grid):
        for x, symbol in enumerate(row):
            if symbol == "X":
                mask[y * 12:min(height, (y + 1) * 12), x * 12:min(width, (x + 1) * 12)] = True
    standing = [spawn]
    for y in range(1, min(len(grid) - 1, height // 12 - 1)):
        for x in range(1, min(len(grid[y]) - 1, width // 12 - 1)):
            if grid[y][x] not in ".@" or grid[y - 1][x] not in ".@" or grid[y + 1][x] not in "#=":
                continue
            if any(grid[ry][rx] in "^v<>UDLR" for ry in range(y - 1, y + 2) for rx in range(x - 1, x + 2)):
                continue
            standing.append((x * 12 + 6, (y + 1) * 12))
    # A short vertical jump reaches upper wall panels without changing terrain.
    jumping = []
    for px, py in standing:
        for rise in (24, 48):
            column, top = int(px // 12), int((py - rise - 24) // 12)
            bottom = int((py - 1) // 12)
            if top >= 0 and all(grid[row][column] in ".@" for row in range(top, bottom + 1)):
                jumping.append((px, py - rise))
    return {"jumping": jumping, "mask": mask, "width": width, "height": height, "standing": standing, "grid": grid}


def reading_position(anchor, ink, geometry, radius=80, allow_jump=False):
    """Find a ground position whose camera contains all ink outside the HUD."""
    for px, py in geometry["standing"] + (geometry["jumping"] if allow_jump else []):
        if (px - anchor["x"]) ** 2 + (py - 8 - anchor["y"]) ** 2 > radius ** 2:
            continue
        vx = max(12, min(px - 240, geometry["width"] - 492))
        vy = max(12, min(py - 135, geometry["height"] - 282))
        if ink[0] < vx + 4 or ink[1] < vy + 4 or ink[2] > vx + 476 or ink[3] > vy + 266:
            continue
        if ink[0] < vx + 110 and ink[1] < vy + 48:
            continue
        return px, py
    return None
