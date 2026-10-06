"""Render the exact baked lettering at native and integer scales for visual review."""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

from audit_wall_memories import places
from wall_memory_geometry import PROJECT
from wall_memory_layout import layout


def place_hash(number, identifier):
    """Match the independent runtime palette choice."""
    value = 0
    for character in f'{number}:{identifier}':
        value = (value * 31 + ord(character)) % 2147483647
    return value


def lettering(anchor, number, metadata, atlas, config):
    """Composite original ink and its one-pixel outline on the real black wall colour."""
    data = layout(anchor['text'], anchor['width'], metadata, atlas)
    image = Image.new('RGB', (data['width'], data['height']), '#070707')
    image.paste('#010101', mask=data['outline'].point(lambda value: round(value * .8)))
    rgb = config['palette'][place_hash(number, anchor['id']) % len(config['palette'])]
    image.paste(tuple(rgb), mask=data['mask'])
    return image


def main():
    """Produce contact sheets with labelled native-size blocks and a focused enlargement."""
    output = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('/private/tmp/wall-memory-review')
    output.mkdir(parents=True, exist_ok=True)
    metadata = json.loads((PROJECT / 'datafiles/narrative/memory_font.json').read_text())
    config = json.loads((PROJECT / 'datafiles/narrative/wall_memories.json').read_text())
    atlas = Image.open(PROJECT / 'datafiles/fonts/memory-alphabet.png').convert('RGBA')
    items = [(number, anchor) for number, _, anchors in places() for anchor in anchors]
    for page in range((len(items) + 17) // 18):
        image = Image.new('RGB', (1080, 600), '#12191c')
        draw = ImageDraw.Draw(image)
        for slot, (number, anchor) in enumerate(items[page * 18:(page + 1) * 18]):
            x, y = slot % 3 * 360, slot // 3 * 100
            draw.text((x + 8, y + 5), f"{number:02} / {anchor['id']}", fill='#72818b')
            text = lettering(anchor, number, metadata, atlas, config)
            image.paste(text, (x + (360 - text.width) // 2, y + 20))
        image.save(output / f'contact-{page + 1}.png')
    selected = [items[0], next(item for item in items if item[0] == 21 and item[1]['role'] == 'regular'),
                next(item for item in items if item[0] == 31 and item[1]['role'] == 'regular')]
    focus = Image.new('RGB', (360, 195), '#070707')
    for row, (number, anchor) in enumerate(selected):
        text = lettering(anchor, number, metadata, atlas, config)
        focus.paste(text, ((360 - text.width) // 2, row * 65 + 5))
    focus.resize((1080, 585), Image.Resampling.NEAREST).save(output / 'lettering-3x.png')
    print(output)


if __name__ == '__main__':
    main()
