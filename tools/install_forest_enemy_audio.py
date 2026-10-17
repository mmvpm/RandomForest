"""Install the final reviewed enemy cues without changing their timing or relative levels."""
import copy
import hashlib
import json
import wave

import numpy as np

from forest_enemy_audio_pcm import encode_pcm, read_pcm
from theme_assets import ROOT, PROJECT, read_resource, register_resources, write_resource

SOUNDS = {
    'slime-land': 'soundResinSlimeLand',
    'slime-attack': 'soundResinSlimeAttack',
    'barrel-burst': 'soundBarkBomberBurst',
    'bat-attack': 'soundForestBatAttack',
    'guard-shot': 'soundBarkGuardShot',
    'guard-impact': 'soundBarkGuardImpact',
    'sweeper-sweep': 'soundRootReaperSweep',
    'sweeper-slam': 'soundRootReaperSlam',
    'maw-bite': 'soundRootMawBite',
    'bat-wake': 'soundForestBatWake',
}


def install_sound(choice, gain):
    """Copy every sample at one common review gain; retain quiet releases as 24-bit PCM."""
    source = ROOT / '.temp/enemy_integration' / choice['file']
    assert hashlib.sha256(source.read_bytes()).hexdigest() == choice['sha256'], source
    samples, params = read_pcm(source)
    amplified = samples * gain
    assert np.max(np.abs(amplified)) < 1, source
    name = SOUNDS[choice['action']]
    target = PROJECT / 'sounds' / name
    target.mkdir(parents=True, exist_ok=True)
    with wave.open(str(target / (name + '.wav')), 'wb') as output:
        output.setparams(params._replace(sampwidth=3))
        output.writeframes(encode_pcm(amplified, 24))
    meta = copy.deepcopy(read_resource(PROJECT / 'sounds/soundSlimeAttack/soundSlimeAttack.yy'))
    meta.update(name=name, **{'%Name': name}, soundFile=name + '.wav',
                duration=params.nframes / params.framerate, sampleRate=params.framerate,
                channelFormat=1 if params.nchannels == 2 else 0)
    write_resource(target / (name + '.yy'), meta)
    return {'action': choice['action'], 'code': choice['code'], 'resource': name,
            'source_sha256': choice['sha256'], 'installed_sha256': hashlib.sha256(
                (target / (name + '.wav')).read_bytes()).hexdigest()}


def main():
    """Install exactly the final ten CC0 cues without adding attribution files to the game."""
    selection = read_resource(ROOT / 'randomforest-enemy-sound-selection-final.json')
    assert {c['action'] for c in selection['selections']} == set(SOUNDS)
    # The browser audition used +18 dB preview copies with its page slider at 25%.
    gain = 10 ** (18 / 20) * selection['page_volume']
    manifest = read_resource(ROOT / '.temp/enemy_integration/audio/manifest.json')
    candidates = {c['code']: c for r in manifest['roles'] for c in r['candidates']}
    installed = []
    for choice in selection['selections']:
        cue = candidates[choice['code']]
        assert cue['license'] == 'CC0 1.0'
        installed.append(install_sound(choice, gain))
    register_resources([('sounds', name) for name in SOUNDS.values()])
    write_resource(ROOT / '.temp/enemy_integration/audio/installed.json',
                   {'gain': gain, 'page_volume': selection['page_volume'], 'sounds': installed})
    print(f'Installed {len(installed)} complete cues at common gain {gain:.8f}.')


if __name__ == '__main__':
    main()
