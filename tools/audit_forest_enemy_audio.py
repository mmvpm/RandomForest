"""Verify candidate provenance, clean WAV boundaries and an untouched game before sound selection."""
import hashlib
import json
import wave
from collections import Counter
from pathlib import Path
import numpy as np
from forest_enemy_audio import ROOT, WORK, decode
from research_forest_enemy_audio import source
from forest_enemy_audio_pcm import read_pcm


def check_audio(manifest):
    """Check real samples, attribution and source reuse for every visible candidate."""
    codes=set();source_ids=[];maximum_duration=0;source_quality={}
    existing_hashes={hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'RandomForest/sounds').rglob('*') if p.is_file() and p.suffix in ('.wav','.mp3','.ogg')}
    expected_round2={'slime-land':10,'slime-attack':2,'barrel-burst':2,'bat-attack':2,'guard-shot':2,
                     'guard-impact':3,'sweeper-sweep':1,'sweeper-slam':8,'maw-bite':1,'bat-wake':2}
    if manifest.get('round')==3:
        expected_round2={'slime-land':1,'slime-attack':1,'barrel-burst':1,'bat-attack':3,'guard-shot':2,
                         'guard-impact':3,'sweeper-sweep':1,'sweeper-slam':5,'maw-bite':1,'bat-wake':3}
    if manifest.get('round')==4:
        expected_round2={'slime-land':1,'slime-attack':1,'barrel-burst':1,'bat-attack':12,'guard-shot':1,
                         'guard-impact':3,'sweeper-sweep':1,'sweeper-slam':1,'maw-bite':1,'bat-wake':2}
    for role in manifest['roles']:
        assert len(role['candidates'])==(expected_round2[role['id']] if manifest['version']==2 else (5 if role['optional'] else 10))
        for clip in role['candidates']:
            assert clip['code'] not in codes;codes.add(clip['code'])
            for recording in clip.get('components',[clip]):
                original=source(recording['source_id'],role['id'])
                source_ids.append(recording['source_id'])
                assert original['url']==recording['url'] and original['license']=='CC0 1.0'
                assert recording['author'] and recording['author']==original['author']
                assert 'kenney' not in (recording['author']+recording['url']).lower()
                raw=WORK/recording['source_file']
                source_hash=hashlib.sha256(raw.read_bytes()).hexdigest()
                assert source_hash==recording['source_sha256'] and source_hash not in existing_hashes
                if recording['source_id'] not in source_quality:
                    audio=decode(raw);clipping=float(np.mean(np.abs(audio)>=.998))
                    assert clipping<.001, f'Source overload: {recording["source_id"]} ({clipping})'
                    source_quality[recording['source_id']]={'author':recording['author'],'peak':float(np.abs(audio).max()),'clipped_fraction':clipping}
            file=WORK.parent/clip['file']
            assert hashlib.sha256(file.read_bytes()).hexdigest()==clip['sha256']
            samples,params=read_pcm(file)
            assert params.nchannels==2 and params.framerate==48000 and params.sampwidth in (2,3)
            duration=params.nframes/params.framerate
            assert .05<=duration<=1.1 and abs(duration-clip['duration'])<.0001
            assert np.all(samples[0]==0) and np.all(samples[-1]==0)
            assert np.max(np.abs(samples))<3000/32768
            assert clip['gain_db']<=0
            maximum_duration=max(duration,maximum_duration)
    repeated={ident:count for ident,count in Counter(source_ids).items() if count>1}
    assert all(count<=({3:5,4:3}.get(manifest.get('round'),2)) for count in repeated.values())
    return {'clips':len(codes),'unique_recordings':len(set(source_ids)),'authors':len({c['author'] for c in source_quality.values()}),
            'shared_recordings':repeated,'maximum_duration':round(maximum_duration,3),'source_quality':source_quality,
            'licenses':'individually checked CC0','kenney_used':False,'old_game_sound_files_used':False,
            'wav_edges_zero':True,'source_overload_excluded':True,'gain_reduction_only':True,'audible_audition':False}


def check_game():
    """Compare all game bytes and the protected plan with the snapshot taken before this work."""
    baseline=json.loads((WORK/'game-baseline.json').read_text())
    current={str(p.relative_to(ROOT)) for p in (ROOT/'RandomForest').rglob('*') if p.is_file()}
    assert current=={p for p in baseline if p.startswith('RandomForest/')}
    for filename,digest in baseline.items():
        assert hashlib.sha256((ROOT/filename).read_bytes()).hexdigest()==digest,f'Changed protected file: {filename}'
    return {'protected_files_unchanged':len(baseline),'plan_unchanged':'.temp/plan.md' in baseline,'game_unchanged':True}


def pcm(clip):
    """Read actual integer samples for comparison with the user's preserved references."""
    with wave.open(str(WORK.parent/clip['file'])) as wav:
        return np.frombuffer(wav.readframes(wav.getnframes()),dtype='<i2').reshape(-1,2)


def check_feedback(manifest):
    """Verify the approved sounds, requested gain ratios and clean separation of swing and impact."""
    if manifest.get('round')==4:
        return check_round4_feedback(manifest)
    if manifest.get('round')==3:
        return check_round3_feedback(manifest)
    if manifest['version']!=2:
        return {}
    first=json.loads((WORK.parent/'revisions/before-feedback-round-2/audio/manifest.json').read_text())
    originals={clip['code']:clip for role in first['roles'] for clip in role['candidates']}
    for clip in originals.values():
        assert hashlib.sha256((WORK.parent/clip['file']).read_bytes()).hexdigest()==clip['sha256']
    roles={role['id']:role for role in manifest['roles']}
    assert [clip['code'] for clip in roles['sweeper-sweep']['candidates']]==['ЖВ08']
    assert [clip['code'] for clip in roles['maw-bite']['candidates']]==['ПУ01']
    candidates={clip['code']:clip for role in manifest['roles'] for clip in role['candidates']}
    for original,ratio in [('ПР10',.5),('ПШ01',.5),('ВЗ04',.6),('МН04',.7),('СС07',.7)]:
        reference=pcm(originals[original]).astype(float)
        revised=pcm(candidates[original+'Р'])
        assert np.array_equal(np.rint(reference*ratio).astype('<i2'),revised),original
    for code in ['СЗ03Р','МП01Р']:
        revised=candidates[code];reference=originals[revised['parent_code']]
        actual=pcm(revised);parent=pcm(reference)
        assert len(actual)<len(parent)
        assert np.all(actual[-1]==0)
        assert -37<=revised['peak_db']<=-23
    for clip in roles['sweeper-slam']['candidates']:
        if 'components' not in clip:
            continue
        air,hit=clip['components']
        assert len(clip['components'])==2
        assert abs(air['offset']+air['peak_time']-.16)<.001
        assert abs(hit['offset']+hit['peak_time']-.34)<.001
        assert air['peak_db']<hit['peak_db']-4
        assert clip['duration']<.7
    assert manifest['reference_page_volume']==.25
    return {'first_round_wavs_preserved':len(originals),'requested_gain_ratios_verified':5,
            'repaired_tails':2,'paired_attacks':6,'reference_page_volume':.25}


def check_round3_feedback(manifest):
    """Check full-length repairs, unchanged attacks and the user's exact ЖУ02 contact reference."""
    originals={}
    for number in (2,3):
        archive=json.loads((WORK.parent/f'revisions/before-feedback-round-{number}/audio/manifest.json').read_text())
        originals.update({clip['code']:clip for role in archive['roles'] for clip in role['candidates']})
    for clip in originals.values():
        assert hashlib.sha256((WORK.parent/clip['file']).read_bytes()).hexdigest()==clip['sha256']
    roles={role['id']:role for role in manifest['roles']}
    approved={'slime-land':'ПР10Р','slime-attack':'ПШ01Р','barrel-burst':'ВЗ04Р',
              'sweeper-sweep':'ЖВ08','maw-bite':'ПУ01'}
    for ident,code in approved.items():
        assert [clip['code'] for clip in roles[ident]['candidates']]==[code]
        assert roles[ident]['candidates'][0]['sha256']==originals[code]['sha256']
    clips={clip['code']:clip for role in manifest['roles'] for clip in role['candidates']}
    cases=[('МН04Р2','МН04Р',.125,.15,.27),('СЗ03Р2','СЗ03',.035,.05,.085),
           ('МП01Р2','МП01',.195,.21,.29)]
    for code,parent_code,untouched,start,end in cases:
        actual=pcm(clips[code]).astype(np.int32);parent=pcm(originals[parent_code]).astype(np.int32)
        assert len(actual)==len(parent),code
        assert np.array_equal(actual[:round(untouched*48000)],parent[:round(untouched*48000)]),code
        assert np.all(np.abs(actual)<=np.abs(parent)),code
        region=slice(round(start*48000),round(end*48000))
        assert np.sum(actual[region].astype(float)**2)<.1*np.sum(parent[region].astype(float)**2),code
    assert np.array_equal(pcm(clips['СС07Р2']),np.rint(pcm(originals['СС07Р']).astype(float)*.5).astype('<i2'))
    for clip in roles['sweeper-slam']['candidates'][1:]:
        air,hit=clip['components']
        assert hit['code']=='ЖУ02' and hit['sha256']==originals['ЖУ02']['sha256']
        assert air['peak_db']>-28 and air['peak_db']<-24
        assert abs(air['offset']+air['peak_time']-.17)<.001
        assert abs(hit['offset']+hit['peak_time']-.42)<.001
    return {'previous_review_wavs_preserved':len(originals),'approved_actions_unchanged':5,
            'full_length_envelope_repairs':3,'wake_amplification_removed':True,
            'additional_shot_gain':.5,'unchanged_ЖУ02_with_firmer_swings':4,'reference_page_volume':.25}


def decay_profile(clip):
    """Measure audible decay and the final noise floor instead of mistaking file duration for a tail."""
    samples,_=read_pcm(WORK.parent/clip['file'])
    rms=np.array([np.sqrt(np.mean(samples[i:i+480]**2)) for i in range(0,len(samples),480)])
    peak=float(rms.max());at=int(np.argmax(rms));crossings={}
    for threshold in (20,30,40):
        last=int(np.flatnonzero(rms>=peak*10**(-threshold/20))[-1])
        crossings[str(threshold)]=round(max(0,last-at)*.01,3)
    ending=20*np.log10(max(np.sqrt(np.mean(samples[-960:]**2))/max(peak,1e-12),1e-12))
    return {'duration':round(len(samples)/48000,4),'decay_seconds':crossings,'last_20ms_relative_db':round(float(ending),2)}


def check_round4_feedback(manifest):
    """Preserve the braided crack, use ten genuinely different alternatives and compare releases to accepted air."""
    archives=[json.loads((WORK.parent/f'revisions/before-feedback-round-{n}/audio/manifest.json').read_text()) for n in (2,3,4)]
    old_files={part['file']:part['sha256'] for archive in archives for role in archive['roles']
               for clip in role['candidates'] for part in [clip,*clip.get('components',[])]}
    for filename,digest in old_files.items():
        assert hashlib.sha256((WORK.parent/filename).read_bytes()).hexdigest()==digest,filename
    originals={clip['code']:clip for archive in archives for role in archive['roles'] for clip in role['candidates']}
    roles={role['id']:role for role in manifest['roles']}
    approved={'slime-land':'ПР10Р','slime-attack':'ПШ01Р','barrel-burst':'ВЗ04Р','guard-shot':'СС07Р2',
              'sweeper-sweep':'ЖВ08','maw-bite':'ПУ01'}
    for ident,code in approved.items():
        assert [c['code'] for c in roles[ident]['candidates']]==[code]
        assert roles[ident]['candidates'][0]['sha256']==originals[code]['sha256']
    clips={clip['code']:clip for role in manifest['roles'] for clip in role['candidates']}
    for code,parent_code,length in [('МН04Р3','МН04Р',.105),('МП01Р3','МП01Р2',.18),('СЗ03Р3','СЗ03',.14)]:
        actual,_=read_pcm(WORK.parent/clips[code]['file']);parent,_=read_pcm(WORK.parent/originals[parent_code]['file'])
        assert np.array_equal(actual[:round(length*48000)],parent[:round(length*48000)]),code
        assert clips[code]['sample_bits']==24
    new=[c for c in roles['bat-attack']['candidates'] if c.get('natural_gesture')]
    old_bat_ids={c['source_id'] for role in archives[0]['roles'] if role['id']=='bat-attack' for c in role['candidates']}
    assert len(new)==10 and len({c['source_id'] for c in new})==10
    assert not old_bat_ids.intersection({c['source_id'] for c in new})
    slam=roles['sweeper-slam']['candidates']
    assert len(slam)==1 and slam[0]['source_id']=='60013' and not slam[0].get('components')
    old_slam=next(role for role in archives[-1]['roles'] if role['id']=='sweeper-slam')
    old_air=next(c for c in old_slam['candidates'] if c['code']=='ЖУ24')['components'][0]
    assert slam[0]['sha256']==old_air['sha256']
    profiles={code:decay_profile(clips[code]) for code in ['ЖВ08','МН04Р3','МП01Р3']}
    reference=profiles['ЖВ08']['decay_seconds']['30']
    for code in ['МН04Р3','МП01Р3']:
        assert profiles[code]['decay_seconds']['30']>=.75*reference,code
        assert profiles[code]['last_20ms_relative_db']<-50,code
        assert .44<=profiles[code]['duration']<=.5
    return {'previous_review_wavs_preserved':len(old_files),'approved_actions_unchanged':6,
            'braided_crack_first_140ms_unchanged':True,'ten_other_bat_recordings':True,
            'slam_is_exact_selected_swing_only':True,'decay_compared_with_accepted_ЖВ08':profiles}


def main():
    """Write the review audit beside the downloaded files, without running or modifying GameMaker."""
    manifest=json.loads((WORK/'manifest.json').read_text())
    report=check_audio(manifest)|check_game()|check_feedback(manifest)
    identity=WORK/'legacy-comparison.json'
    if identity.exists():
        comparison=json.loads(identity.read_text())
        assert not comparison['suspected_reuse'], 'Candidate repeats existing game audio'
        report['existing_recording_comparison']=comparison['existing_short_files']
    (WORK/'audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({key:value for key,value in report.items() if key!='source_quality'},ensure_ascii=False,indent=2))


if __name__=='__main__':main()
