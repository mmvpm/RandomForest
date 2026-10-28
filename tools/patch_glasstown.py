"""Apply the approved Glasstown glyph edits on its original 64-unit pixel grid."""
import hashlib
import shutil
from pathlib import Path

from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont


ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / 'RandomForest/datafiles/glasstown.ttf'
WORK = ROOT / '.temp/dialogue_font'
PIXEL = 64
GLYPHS = {
    'М': (0, ['#.....#', '#.....#', '##...##', '#.#.#.#', '#.#.#.#',
              '#..#..#', '#..#..#', '#.....#', '#.....#']),
    'м': (0, ['#.....#', '##...##', '#.#.#.#', '#..#..#', '#.....#', '#.....#']),
    'У': (0, ['#...#', '#...#', '#...#', '#...#', '#...#', '.####',
              '....#', '....#', '.###.']),
    'Х': (0, ['#...#', '#...#', '.#.#.', '.#.#.', '..#..', '.#.#.',
              '.#.#.', '#...#', '#...#']),
    'Ы': (0, ['#....#.', '#....#.', '#....#.', '#....#.', '###..#.',
              '#..#.#.', '#..#.#.', '#..#.#.', '###..#.']),
    'ы': (0, ['#....#.', '#....#.', '###..#.', '#..#.#.', '#..#.#.', '###..#.']),
    'й': (0, ['.##.', '....', '#..#', '#.##', '#.##', '##.#', '##.#', '#..#']),
}
GLYPHS['M'] = GLYPHS['М']


def draw_glyph(bottom, rows):
    """Trace horizontal pixel runs as rectangles without curves or hinting."""
    pen = TTGlyphPen(None)
    for row_index, row in enumerate(rows):
        start = None
        for column, cell in enumerate(row + '.'):
            if cell == '#' and start is None:
                start = column
            if cell == '.' and start is not None:
                left, right = start * PIXEL, column * PIXEL
                low = (bottom + len(rows) - row_index - 1) * PIXEL
                high = low + PIXEL
                pen.moveTo((left, low))
                pen.lineTo((left, high))
                pen.lineTo((right, high))
                pen.lineTo((right, low))
                pen.closePath()
                start = None
    return pen.glyph()


def main():
    """Rebuild from the saved upstream font, restoring every unrequested glyph."""
    WORK.mkdir(parents=True, exist_ok=True)
    original = WORK / 'glasstown-original.ttf'
    if not original.exists():
        shutil.copyfile(FONT, original)
    font = TTFont(original, recalcTimestamp=False)
    cmap = font.getBestCmap()
    for character, (bottom, rows) in GLYPHS.items():
        font['glyf'][cmap[ord(character)]] = draw_glyph(bottom, rows)
    font.save(FONT)
    source = TTFont(original)
    changed = {cmap[ord(c)] for c in GLYPHS}
    for name in font.getGlyphOrder():
        if name not in changed:
            assert font['glyf'][name].compile(font['glyf']) == source['glyf'][name].compile(source['glyf']), name
    assert font['hmtx'].metrics == source['hmtx'].metrics
    assert font.getBestCmap() == source.getBestCmap()
    assert all(record.toUnicode() == source['name'].names[i].toUnicode()
               for i, record in enumerate(font['name'].names))
    print('Edited:', ' '.join(GLYPHS))
    print('Original у restored; Latin m and all unrequested glyphs, metrics and license preserved.')
    print('Original SHA-256:', hashlib.sha256(original.read_bytes()).hexdigest())


if __name__ == '__main__':
    main()
