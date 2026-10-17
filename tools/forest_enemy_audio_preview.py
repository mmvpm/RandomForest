"""Bundle audible comparison copies so local gallery playback needs no media-file requests."""
import base64
import hashlib
import io
import json
import wave
from pathlib import Path

import numpy as np
from forest_enemy_audio_pcm import read_pcm,encode_pcm

WORK = Path(__file__).resolve().parents[1] / '.temp/enemy_integration'
GAIN_DB = 18


def preview_uri(path, expected_hash):
    """Raise preview gain uniformly, preserving timing and refusing clipping or changed originals."""
    raw = path.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == expected_hash
    samples,params = read_pcm(path)
    amplified = samples * 10 ** (GAIN_DB / 20)
    assert np.max(np.abs(amplified)) < 1, f'Preview would clip: {path}'
    output = io.BytesIO()
    with wave.open(output, 'wb') as target:
        target.setparams(params)
        target.writeframes(encode_pcm(amplified,params.sampwidth*8))
    return 'data:audio/wav;base64,' + base64.b64encode(output.getvalue()).decode('ascii')


def build_previews():
    """Write self-contained audio separately from attribution and the unchanged downloadable WAVs."""
    manifest = json.loads((WORK / 'audio/manifest.json').read_text())
    clips = {clip['code']: preview_uri(WORK / clip['file'], clip['sha256'])
             for role in manifest['roles'] for clip in role['candidates']}
    data = {'gain_db': GAIN_DB, 'clips': clips}
    (WORK / 'audio-preview-data.js').write_text(
        'window.FOREST_ENEMY_AUDIO_PREVIEWS=' + json.dumps(data, ensure_ascii=False) + ';\n')
    return len(clips)


if __name__ == '__main__':
    print(f'{build_previews()} embedded previews; comparison gain +{GAIN_DB} dB.')
