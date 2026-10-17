"""Read cached public Freesound searches and require each selected recording's CC0 license."""
import json
from pathlib import Path
from urllib.parse import quote, urlparse, unquote
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / '.temp/enemy_integration/audio'
RESEARCH = WORK / 'research'


def search(path):
    """Extract complete author descriptions and HQ preview locations from cached search results."""
    query = path.stem.removeprefix('search-').replace('-', ' ')
    soup = BeautifulSoup(path.read_text(), 'html.parser')
    records = []
    for player in soup.select('.bw-player[data-sound-id]'):
        description = player.parent.parent.select_one('.overflow-hidden[title]')
        author, ident = player['data-username'], player['data-sound-id']
        records.append({'id': ident, 'author': author, 'title': player['data-title'],
                        'duration': float(player['data-duration']), 'queries': [query],
                        'description': description.get('title', '') if description else '',
                        'url': f'https://freesound.org/people/{quote(author)}/sounds/{ident}/',
                        'preview': player['data-mp3'].replace('-lq.mp3', '-hq.mp3')})
    return records


def source(ident, role):
    """Verify the individual author's license and actual sound ID, without trusting search filters."""
    path = RESEARCH / f'{ident}.html'
    soup = BeautifulSoup(path.read_text(), 'html.parser')
    license_link = soup.select_one('a[href*="creativecommons.org/publicdomain/zero/1.0"]')
    player = soup.select_one('.bw-player[data-sound-id]')
    if not license_link or not player or player['data-sound-id'] != str(ident):
        raise ValueError(f'Wrong recording or not verified CC0: {ident}')
    description = soup.select_one('meta[name="twitter:description"]')
    text = BeautifulSoup(description['content'], 'html.parser').get_text(' ', strip=True) if description else ''
    author = soup.select_one('meta[property="og:audio:artist"]')['content']
    canonical = soup.select_one('meta[property="og:url"]')['content']
    parsed = urlparse(canonical)
    if not author or parsed.netloc != 'freesound.org' or unquote(parsed.path) != f'/people/{author}/sounds/{ident}/':
        raise ValueError(f'Incomplete attribution or wrong canonical URL: {ident}')
    return {'id': str(ident), 'author': author, 'title': player['data-title'], 'role': role,
            'duration': float(player['data-duration']), 'description': text,
            'preview': player['data-mp3'].replace('-lq.mp3', '-hq.mp3'),
            'source_file': f'sources/{ident}.mp3', 'license': 'CC0 1.0',
            'license_url': 'https://creativecommons.org/publicdomain/zero/1.0/',
            'url': f'https://freesound.org/people/{quote(author)}/sounds/{ident}/'}


def main():
    """Keep selection metadata and cached research reproducible without further network calls."""
    inventory = {}
    for path in sorted(RESEARCH.glob('search-*.html')):
        for record in search(path):
            if record['id'] in inventory:
                inventory[record['id']]['queries'].extend(record['queries'])
            else:
                inventory[record['id']] = record
    (RESEARCH / 'inventory.json').write_text(json.dumps(list(inventory.values()), ensure_ascii=False, indent=2))
    roles = json.loads((RESEARCH / 'shortlist.json').read_text())
    verified = [source(ident, role) for role, ids in roles.items() for ident in ids]
    (RESEARCH / 'verified-sources.json').write_text(json.dumps(verified, ensure_ascii=False, indent=2))
    print(f'{len(inventory)} researched; {len(verified)} selected entries with individually verified CC0 licenses.')


if __name__ == '__main__':
    main()
