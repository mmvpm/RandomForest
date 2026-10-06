"""Synchronize the editor atlas from the game's accepted Caveat Regular frames."""

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1] / "RandomForest"
DATA = ROOT / "datafiles"
SPRITE = ROOT / "sprites" / "sMemoryAlphabet"
SIZE, WEIGHT = 18, 400
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
    for index, character in enumerate(characters):
        frame = resource["frames"][index]["name"]
        image = Image.open(SPRITE / f"{frame}.png").convert("RGBA")
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
                    atlas={"columns": COLUMNS, "cell_width": CELL_WIDTH,
                           "cell_height": CELL_HEIGHT, "file": "fonts/memory-alphabet.png"})
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
    print(f"Synchronized {len(characters)} original glyphs: Caveat Regular, {SIZE}px")


if __name__ == "__main__":
    main()
