"""Share the game's integer glyph geometry with placement audits and previews."""

import math

from PIL import Image, ImageFilter


def measure(text, metadata):
    """Measure cropped sprite-font advances, including spaces."""
    advances = dict(zip(metadata["characters"], metadata["advances"]))
    return sum(advances.get(character, 0) for character in text)


def wrap(text, width, metadata):
    """Match runtime word wrapping, long-word splits and explicit newlines."""
    lines = []
    for paragraph in text.split("\n"):
        line = ""
        for word in paragraph.split(" "):
            candidate = f"{line} {word}" if line else word
            if line and measure(candidate, metadata) > width:
                lines.append(line)
                line = word
            else:
                line = candidate
            while measure(line, metadata) > width:
                cut = 1
                while cut < len(line) and measure(line[:cut + 1], metadata) <= width:
                    cut += 1
                lines.append(line[:cut])
                line = line[cut:]
        if line or not paragraph:
            lines.append(line)
    return lines


def round_pixel(value):
    """Match whole-pixel rounding without Python's even-number tie rule."""
    return math.floor(value + 0.5)


def layout(text, width, metadata, atlas, line_height=24):
    """Return complete centred lines and the exact glyph-plus-outline mask."""
    width = max(32, math.ceil(width))
    lines = wrap(text, width - 6, metadata)
    height = metadata.get("glyph_height", 26) + 6 + max(0, len(lines) - 1) * line_height
    mask = Image.new("L", (width, height))
    positions = [round_pixel((width - measure(line, metadata)) / 2) for line in lines]
    cell = metadata["atlas"]
    advances = dict(zip(metadata["characters"], metadata["advances"]))
    for row, line in enumerate(lines):
        cursor = positions[row]
        for character in line:
            index = metadata["characters"].find(character)
            if index < 0:
                continue
            box = metadata["glyph_bounds"][index]
            if character != " ":
                left = index % cell["columns"] * cell["cell_width"]
                top = index // cell["columns"] * cell["cell_height"]
                glyph = atlas.crop((left + box[0], top + box[1], left + box[2], top + box[3])).getchannel("A")
                mask.paste(glyph, (cursor, 3 + row * line_height + box[1]))
            cursor += advances[character]
    outline = mask.filter(ImageFilter.MaxFilter(3))
    return {"width": width, "height": height, "lines": lines, "line_x": positions,
            "mask": mask, "outline": outline, "ink": outline.getbbox()}
