"""Build the approved original pixel lettering and synchronize the editor atlas."""

import argparse
import hashlib
import json
import uuid
from pathlib import Path

from PIL import Image
from theme_assets import read_resource
from wall_pixel_glyphs import glyphs


ROOT = Path(__file__).resolve().parents[1] / "RandomForest"
SIZE, WEIGHT = 16, 400
CELL_WIDTH, CELL_HEIGHT, COLUMNS = 22, 26, 16


def main():
    """Keep glyph pixels and give each bitmap a stable, content-specific frame identity."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-dir", type=Path, default=ROOT)
    args = parser.parse_args()
    sprite = args.project_dir / "sprites" / "sMemoryAlphabet"
    data = args.project_dir / "datafiles"
    resource_path = sprite / "sMemoryAlphabet.yy"
    resource_text = resource_path.read_text()
    resource = read_resource(resource_path)
    metadata_path = data / "narrative" / "memory_font.json"
    metadata = json.loads(metadata_path.read_text())
    characters = metadata["characters"]
    atlas = Image.new("RGBA", (COLUMNS * CELL_WIDTH,
                              ((len(characters) + COLUMNS - 1) // COLUMNS) * CELL_HEIGHT))
    bounds, advances = [], []
    original_glyphs = glyphs()
    frame_ids, obsolete = {}, []
    layer = resource["layers"][0]["name"]
    for index, character in enumerate(characters):
        old_frame = resource["frames"][index]["name"]
        image = Image.open(sprite / f"{old_frame}.png").convert("RGBA")
        if character in original_glyphs and character != " ":
            # Match the approved native-size preview; preserve unrequested Latin glyphs.
            glyph = original_glyphs[character]
            ink = Image.new("RGBA", glyph.size, "white")
            ink.putalpha(glyph.convert("L"))
            image = Image.new("RGBA", (CELL_WIDTH, CELL_HEIGHT))
            image.paste(ink, (0, 2))
        if image.size != (CELL_WIDTH, CELL_HEIGHT):
            raise ValueError(f"Unexpected glyph size: {character!r}")
        box = image.getchannel("A").getbbox()
        if box is None:
            raise ValueError(f"Missing glyph: {character!r}")
        # GameMaker can reuse the old packed bitmap when replacement PNGs keep its frame ID.
        digest = hashlib.sha256(image.tobytes()).hexdigest()
        frame = str(uuid.uuid5(uuid.NAMESPACE_URL,
                              f"RandomForest/WallNotesPixel/1/{ord(character)}/{digest}"))
        frame_ids[old_frame] = frame
        image.save(sprite / f"{frame}.png")
        layer_path = sprite / "layers" / frame / f"{layer}.png"
        layer_path.parent.mkdir(parents=True, exist_ok=True)
        image.save(layer_path)
        if old_frame != frame:
            obsolete.append(old_frame)
        bounds.append(list(box))
        advances.append(box[2] - box[0] + 1)
        atlas.paste(image, (index % COLUMNS * CELL_WIDTH, index // COLUMNS * CELL_HEIGHT))
    atlas.save(data / "fonts" / "memory-alphabet.png")
    metadata.update(advances=advances, glyph_bounds=bounds,
                    font_size=SIZE, weight=WEIGHT, glyph_height=CELL_HEIGHT,
                    family="Wall Notes Pixel", cap_height=11, x_height=8,
                    atlas={"columns": COLUMNS, "cell_width": CELL_WIDTH,
                           "cell_height": CELL_HEIGHT, "file": "fonts/memory-alphabet.png"})
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
    # Update frame declarations and sequence references without reformatting IDE metadata.
    for old_frame, frame in frame_ids.items():
        resource_text = resource_text.replace(f'"{old_frame}"', f'"{frame}"')
    resource_path.write_text(resource_text)
    # Both the sprite and editor atlas now reference the verified permanent replacement files.
    for frame in obsolete:
        (sprite / f"{frame}.png").unlink()
        (sprite / "layers" / frame / f"{layer}.png").unlink()
        (sprite / "layers" / frame).rmdir()
    print(f"Synchronized {len(characters)} glyphs: Wall Notes Pixel, {SIZE}px")


if __name__ == "__main__":
    main()
