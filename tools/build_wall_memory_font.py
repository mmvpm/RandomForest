"""Build the approved original pixel lettering and synchronize the editor atlas."""

import json
from pathlib import Path

from PIL import Image
from wall_pixel_glyphs import glyphs


ROOT = Path(__file__).resolve().parents[1] / "RandomForest"
DATA = ROOT / "datafiles"
SPRITE = ROOT / "sprites" / "sMemoryAlphabet"
SIZE, WEIGHT = 16, 400
CELL_WIDTH, CELL_HEIGHT, COLUMNS = 22, 26, 16


def main():
    """Preserve glyph pixels and rebuild only their atlas and layout metadata."""
    resource = json.loads((SPRITE / "sMemoryAlphabet.yy").read_text())
    metadata_path = DATA / "narrative" / "memory_font.json"
    metadata = json.loads(metadata_path.read_text())
    characters = metadata["characters"]
    atlas = Image.new("RGBA", (COLUMNS * CELL_WIDTH,
                              ((len(characters) + COLUMNS - 1) // COLUMNS) * CELL_HEIGHT))
    bounds, advances = [], []
    original_glyphs = glyphs()
    for index, character in enumerate(characters):
        frame = resource["frames"][index]["name"]
        image = Image.open(SPRITE / f"{frame}.png").convert("RGBA")
        if character in original_glyphs and character != " ":
            # Match the approved native-size preview; preserve unrequested Latin glyphs.
            glyph = original_glyphs[character]
            ink = Image.new("RGBA", glyph.size, "white")
            ink.putalpha(glyph.convert("L"))
            image = Image.new("RGBA", (CELL_WIDTH, CELL_HEIGHT))
            image.paste(ink, (0, 2))
            image.save(SPRITE / f"{frame}.png")
            layer = resource["layers"][0]["name"]
            image.save(SPRITE / "layers" / frame / f"{layer}.png")
        if image.size != (CELL_WIDTH, CELL_HEIGHT):
            raise ValueError(f"Unexpected glyph size: {character!r}")
        box = image.getchannel("A").getbbox()
        if box is None:
            raise ValueError(f"Missing glyph: {character!r}")
        bounds.append(list(box))
        advances.append(box[2] - box[0] + 1)
        atlas.paste(image, (index % COLUMNS * CELL_WIDTH, index // COLUMNS * CELL_HEIGHT))
    atlas.save(DATA / "fonts" / "memory-alphabet.png")
    metadata.update(advances=advances, glyph_bounds=bounds,
                    font_size=SIZE, weight=WEIGHT, glyph_height=CELL_HEIGHT,
                    family="Wall Notes Pixel", cap_height=11, x_height=8,
                    atlas={"columns": COLUMNS, "cell_width": CELL_WIDTH,
                           "cell_height": CELL_HEIGHT, "file": "fonts/memory-alphabet.png"})
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
    print(f"Synchronized {len(characters)} glyphs: Wall Notes Pixel, {SIZE}px")


if __name__ == "__main__":
    main()
