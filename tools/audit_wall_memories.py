"""Check every authored inscription against its exact black wall and baked glyphs."""

import json
from pathlib import Path

import numpy as np
from PIL import Image

from wall_memory_geometry import PROJECT, ROOMS, read_yy, room_geometry, reading_position
from wall_memory_layout import layout, round_pixel
from build_wall_memory_font import SIZE, WEIGHT, CELL_WIDTH, CELL_HEIGHT


def places():
    """Load manual properties and generated metadata into the same place schema."""
    for number, name in enumerate(ROOMS, 1):
        path = PROJECT / 'rooms' / name / f'{name}.yy'
        data = read_yy(path)
        anchors = []
        for layer in data['layers']:
            for item in layer.get('instances', []):
                if item['objectId']['name'] != 'oWallMemoryAnchor':
                    continue
                props = {prop['propertyId']['name']: prop['value'] for prop in item['properties']}
                assert 'align' not in props and 'text_id' not in props
                anchors.append(dict(id=props['anchor_id'], x=item['x'], y=item['y'],
                                    width=float(props['width']), text=props['text'], role=props['role'],
                                    min_collected=int(props['min_collected']),
                                    requires_all_previous=props['requires_all_previous'] == 'True'))
        yield number, path, anchors
    for path in sorted((PROJECT / 'datafiles/challenge_levels').glob('[0-9][0-9].json')):
        yield int(path.stem) + 10, path, json.loads(path.read_text()).get('wall_memories', [])


def check_font(metadata, atlas):
    """Detect missing ink, clipped letters and mismatched frames or atlas metadata."""
    sprite = PROJECT / 'sprites/sMemoryAlphabet'
    resource = read_yy(sprite / 'sMemoryAlphabet.yy')
    assert metadata['font_size'] == SIZE and metadata['weight'] == WEIGHT
    assert metadata['glyph_height'] == CELL_HEIGHT
    assert (resource['width'], resource['height']) == (CELL_WIDTH, CELL_HEIGHT)
    layer = resource['layers'][0]['name']
    for index, character in enumerate(metadata['characters']):
        frame = Image.open(sprite / (resource['frames'][index]['name'] + '.png')).convert('RGBA')
        assert frame.size == (CELL_WIDTH, CELL_HEIGHT)
        alpha = frame.getchannel('A')
        assert set(np.unique(np.array(alpha))) <= {0, 85, 170, 255}
        assert list(alpha.getbbox()) == metadata['glyph_bounds'][index]
        assert alpha.getbbox()[2] - alpha.getbbox()[0] + 1 == metadata['advances'][index]
        source = Image.open(sprite / 'layers' / resource['frames'][index]['name'] / f'{layer}.png')
        assert np.array_equal(np.array(frame), np.array(source))
        x, y = index % 16 * CELL_WIDTH, index // 16 * CELL_HEIGHT
        assert np.array_equal(np.array(frame), np.array(atlas.crop((x, y, x + CELL_WIDTH, y + CELL_HEIGHT))))
        box = alpha.getbbox()
        assert 0 <= box[0] < box[2] <= CELL_WIDTH and 0 <= box[1] < box[3] <= CELL_HEIGHT, character


def audit():
    """Require intact wall pixels, readable camera placement and separated lettering."""
    metadata = json.loads((PROJECT / 'datafiles/narrative/memory_font.json').read_text())
    atlas = Image.open(PROJECT / 'datafiles/fonts/memory-alphabet.png').convert('RGBA')
    check_font(metadata, atlas)
    project = read_yy(PROJECT / 'RandomForest.yyp')
    resources = {item['id']['name']: item['id']['path'] for item in project['resources']}
    for name in ('scriptWallMemoryProgress', 'soundWallMemoryReveal'):
        assert (PROJECT / resources[name]).is_file()
    assert 'shWallMemoryReveal' not in resources
    total, jumps = 0, []
    for number, path, anchors in places():
        geometry = room_geometry(number, path)
        boxes, ids = [], set()
        for anchor in anchors:
            assert anchor['id'] not in ids
            ids.add(anchor['id'])
            assert 'align' not in anchor and 'text_id' not in anchor
            assert set(anchor['text']) <= set(metadata['characters']) | {'\n'}
            data = layout(anchor['text'], anchor['width'], metadata, atlas)
            assert len(data['lines']) <= 3
            box = data['ink']
            left = round_pixel(anchor['x'] - data['width'] / 2)
            top = round_pixel(anchor['y'] - data['height'] / 2)
            ink = (left + box[0], top + box[1], left + box[2], top + box[3])
            assert 0 <= ink[0] < ink[2] <= geometry['width']
            assert 0 <= ink[1] < ink[3] <= geometry['height']
            shape = np.array(data['outline'].crop(box)) > 0
            assert not np.any(shape & ~geometry['mask'][ink[1]:ink[3], ink[0]:ink[2]]), (number, anchor['id'])
            for previous in boxes:
                assert not (ink[0] < previous[2] + 3 and ink[2] > previous[0] - 3
                            and ink[1] < previous[3] + 3 and ink[3] > previous[1] - 3), (number, anchor['id'])
            boxes.append(ink)
            assert reading_position(anchor, ink, geometry, allow_jump=True), (number, anchor['id'])
            if not reading_position(anchor, ink, geometry):
                jumps.append(f"{number}:{anchor['id']}")
            total += 1
    print(f'{total} places: exact black-wall pixels, camera/HUD, radius 80, separation, conditions schema passed.')
    print(f'{len(metadata["characters"])} original glyphs: alpha, bounds, frame/layer/atlas parity passed.')
    print('Short-jump reading positions:', ', '.join(jumps))


if __name__ == '__main__':
    audit()
