"""Build the second listening round from preserved originals and the user's exported feedback."""
import copy
import hashlib
import json
import wave

import numpy as np

from forest_enemy_audio import RATE, WORK, prepare
from forest_enemy_audio_preview import build_previews
from forest_enemy_audio_pcm import read_pcm, encode_pcm
from research_forest_enemy_audio import source

ARCHIVE = WORK.parent / 'revisions/before-feedback-round-2/audio/manifest.json'
PLAN = WORK / 'round2-plan.json'


def read_clip(clip):
    """Read a prepared WAV without renormalizing the user's comparison reference."""
    return read_pcm(WORK.parent / clip['file'])[0]


def fade_tail(samples, milliseconds):
    """Fade only the selected tail to silence with a smooth, click-free curve."""
    count = min(len(samples), round(milliseconds * RATE / 1000))
    if count:
        samples[-count:] *= ((1 + np.cos(np.linspace(0, np.pi, count))) / 2)[:, None]


def write_clip(samples, metadata, bits=16):
    """Write one revised WAV and refresh all measurements and its content hash."""
    assert np.max(np.abs(samples)) < 1, metadata['code']
    pcm = encode_pcm(samples,bits)
    quantized = np.rint(samples*(1<<(bits-1)))/(1<<(bits-1))
    filename = 'audio/clips/' + metadata['code'] + '.wav'
    path = WORK.parent / filename
    with wave.open(str(path), 'wb') as wav:
        wav.setnchannels(2)
        wav.setsampwidth(bits//8)
        wav.setframerate(RATE)
        wav.writeframes(pcm)
    magnitude = np.max(np.abs(quantized), axis=1)
    peak = float(magnitude.max())
    bins = [float(part.max()) / max(peak, 1e-9) for part in np.array_split(magnitude, 64)]
    return dict(metadata, file=filename, sample_bits=bits,duration=round(len(samples) / RATE, 4),
                peak_db=round(20 * np.log10(max(peak, 1e-9)), 2),
                peak_time=round(int(np.argmax(np.sum(quantized ** 2, axis=1))) / RATE, 4),
                waveform=[round(value, 3) for value in bins],
                sha256=hashlib.sha256(path.read_bytes()).hexdigest())


def revise(originals, entry):
    """Keep the reference intact and create only the requested attenuation or tail repair."""
    original = originals[entry['from']]
    assert hashlib.sha256((WORK.parent / original['file']).read_bytes()).hexdigest() == original['sha256']
    samples = read_clip(original)
    if 'end' in entry:
        samples = samples[:round(entry['end'] * RATE)].copy()
    factor = entry.get('gain', 1)
    samples *= factor
    fade_tail(samples, entry.get('fade_out_ms', 0))
    metadata = dict(original, code=entry['code'], label=entry['label'],
                    tag='Доработка', parent_code=entry['from'], edit_note=entry['edit_note'],
                    relative_gain=factor, gain_db=round(original['gain_db'] + 20 * np.log10(factor), 2),
                    fade_out_ms=entry.get('fade_out_ms', 5))
    metadata['trim'] = [original['trim'][0], round(original['trim'][0] + len(samples) / RATE, 5)]
    return write_clip(samples, metadata)


def new_event(entry, role_id):
    """Prepare one real, licensed Foley gesture, leaving room for its natural decay."""
    original = source(entry['source'], role_id)
    selection = {key: entry[key] for key in ('code', 'label', 'cut')}
    clip = prepare(original, selection, 1.1, entry['peak_db'])
    samples = read_clip(clip)
    fade_tail(samples, entry.get('fade_out_ms', 20))
    clip.update(tag='Новый', edit_note=entry['edit_note'], fade_out_ms=entry.get('fade_out_ms', 20))
    return write_clip(samples, clip)


def paired_attack(entry, role_id):
    """Join one physical swing and one physical impact without pitch changes or synthetic layers."""
    parts = []
    for index, spec in enumerate(entry['parts']):
        selection = dict(spec, code=entry['code'] + ('-air' if index == 0 else '-hit'),
                         label=entry['label'], edit_note=entry['edit_note'])
        clip = new_event(selection, role_id)
        samples = read_clip(clip)
        # Align the recorded gesture's peak to the authored swing/contact timing.
        anchor = .16 if index == 0 else .34
        offset = max(0, round((anchor - clip['peak_time']) * RATE))
        clip['offset'] = round(offset / RATE, 5)
        parts.append((clip, samples, offset))
    length = max(offset + len(samples) for _, samples, offset in parts)
    combined = np.zeros((length, 2))
    for _, samples, offset in parts:
        combined[offset:offset + len(samples)] += samples
    metadata = dict(parts[-1][0], code=entry['code'], label=entry['label'], tag='Новый',
                    components=[part[0] for part in parts], sync_time=.34,
                    edit_note=entry['edit_note'], composition='physical swing followed by physical impact')
    metadata.pop('offset', None)
    return write_clip(combined, metadata)


def credits(manifest):
    """Credit every physical recording, including both components of each paired attack."""
    lines = [f'Random Forest · sound review round {manifest["round"]} · CC0 1.0',
             'Source HQ MP3 previews retained. No synthesis, EQ, pitch or speed changes.',
             'Comparison player gain +18 dB; reference page volume 25%.', '']
    for role in manifest['roles']:
        for clip in role['candidates']:
            lines.append(f'{clip["code"]} | {clip["label"]} | {clip.get("edit_note", "Preserved reference")}')
            for recording in clip.get('components', [clip]):
                lines.append(f'{recording["title"]} by {recording["author"]}\n{recording["url"]}\n'
                             f'CC0 1.0 | {recording["license_url"]}\n'
                             f'Excerpt {recording["trim"]}; gain {recording["gain_db"]} dB; '
                             f'offset {recording.get("offset", 0)} s')
            lines.append('')
    (WORK / 'ATTRIBUTION.txt').write_text('\n'.join(lines) + '\n')


def build_round2():
    """Publish only requested references, repairs and new candidates while retaining the first round."""
    first = json.loads(ARCHIVE.read_text())
    plan = json.loads(PLAN.read_text())
    feedback = {row['action']: row for row in json.loads((WORK / 'feedback-round-2.json').read_text())['selections']}
    originals = {clip['code']: clip for role in first['roles'] for clip in role['candidates']}
    roles = []
    for initial in first['roles']:
        role = copy.deepcopy(initial)
        spec = plan['roles'][role['id']]
        role.update(review_status=spec['status'], review_summary=spec['summary'],
                    feedback_note=feedback[role['id']]['note'],
                    previous_choice=feedback[role['id']]['code'], candidates=[])
        for entry in spec['candidates']:
            if 'keep' in entry:
                clip = dict(originals[entry['keep']], tag=entry.get('tag', 'Исходный'), edit_note='Без изменений')
            elif 'from' in entry:
                clip = revise(originals, entry)
            elif 'parts' in entry:
                clip = paired_attack(entry, role['id'])
            else:
                clip = new_event(entry, role['id'])
            role['candidates'].append(clip)
        roles.append(role)
    recordings = {recording['source_id'] for role in roles for clip in role['candidates']
                  for recording in clip.get('components', [clip])}
    manifest = dict(version=2, round=2, roles=roles, source_count=len(recordings),
                    reference_page_volume=.25, auditioned_by_agent=False,
                    editing='requested gain reductions and smooth tail cuts; physical swing + impact pairs')
    (WORK / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    (WORK.parent / 'audio-data.js').write_text('window.FOREST_ENEMY_AUDIO=' + json.dumps(manifest, ensure_ascii=False) + ';\n')
    credits(manifest)
    build_previews()
    print(f'Round 2: {sum(len(role["candidates"]) for role in roles)} candidates, {len(recordings)} recordings.')


if __name__ == '__main__':
    build_round2()
