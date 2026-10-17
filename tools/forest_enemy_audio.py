"""Extract short natural Foley candidates; never install sounds into the GameMaker project."""
import hashlib
import json
import subprocess
import wave
from pathlib import Path
import numpy as np
from forest_enemy_audio_preview import build_previews

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / '.temp/enemy_integration/audio'
RATE = 48000
ROLES = {
 'slime-land': ('slime','Приземление','hop',10,'ПР',0.8,-26),
 'slime-attack': ('slime','Выброс шипов','attack',4,'ПШ',0.72,-23),
 'barrel-burst': ('barrel','Взрыв спор','attack',11,'ВЗ',1.1,-22),
 'bat-attack': ('bat','Тихий налёт','attack',3,'МН',0.75,-29),
 'guard-shot': ('guard','Выпуск семени','attack-1',3,'СС',1.0,-23),
 'guard-impact': ('guard','Наземный выброс','attack-2',3,'СЗ',0.9,-23),
 'sweeper-sweep': ('sweeper','Широкий взмах','attack-sweep',3,'ЖВ',1.05,-24),
 'sweeper-slam': ('sweeper','Верхний удар','attack-slam',5,'ЖУ',1.0,-23),
 'maw-bite': ('maw','Выпад и захлопывание','attack',3,'ПУ',0.85,-24),
 'bat-wake': ('bat','Отлипание от потолка · опционально','wake',2,'МП',0.6,-32),
}


def decode(path):
    """Keep both channels of the HQ preview and analyze energy without changing its pitch or timing."""
    raw = subprocess.run(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ar',str(RATE),'-ac','2','pipe:1'],check=True,capture_output=True).stdout
    return np.frombuffer(raw,dtype='<f4').reshape(-1,2).copy()


def events(audio):
    """Find separate recorded gestures, joining pauses shorter than 100 ms within one gesture."""
    block = 240
    padded = np.pad(audio,((0,(-len(audio)) % block),(0,0)))
    rms = np.sqrt(np.mean(padded.reshape(-1,block,2)**2,axis=(1,2)))
    floor = np.percentile(rms,15)
    threshold = max(float(rms.max())*.025,float(floor)*1.6,0.000025)
    active = rms>threshold
    indexes = np.flatnonzero(active)
    if not len(indexes):
        raise ValueError('Silent recording')
    groups = np.split(indexes,np.flatnonzero(np.diff(indexes)>20)+1)
    result = []
    for group in groups:
        start = max(0,int(group[0]*block)-int(RATE*.025))
        end = min(len(audio),int((group[-1]+1)*block)+int(RATE*.075))
        duration = (end-start)/RATE
        if duration>=.07:
            result.append((start,end,float(np.sum(audio[start:end]**2))))
    return result


def region(audio, maximum, override=None):
    """Choose a whole short gesture; require a reviewed cut when no complete event fits."""
    if override:
        return round(override[0]*RATE),min(len(audio),round(override[1]*RATE))
    if len(audio)/RATE <= 1.35:
        signal=np.max(np.abs(audio),axis=1)
        active=np.flatnonzero(signal>max(float(signal.max())*.004,0.000025))
        if len(active):
            start=max(0,int(active[0])-round(.015*RATE))
            end=min(len(audio),int(active[-1])+round(.045*RATE))
            if (end-start)/RATE<=maximum:
                return start,end
    options=[event for event in events(audio) if (event[1]-event[0])/RATE<=maximum]
    if not options:
        longest=max(events(audio),key=lambda event:event[2])
        raise ValueError(f'No whole event below {maximum}s; strongest span {longest[0]/RATE:.3f}–{longest[1]/RATE:.3f}')
    # A coherent high-energy gesture is preferable to a tiny isolated handling click.
    return max(options,key=lambda event:event[2])[:2]


def prepare(source, selection, maximum, target_db):
    """Only trim, apply five-millisecond edge fades and reduce gain; preserve the recording's texture."""
    file=WORK/source['source_file'];audio=decode(file)
    start,end=region(audio,maximum,selection.get('cut'))
    clip=audio[start:end].copy()
    if not len(clip): raise ValueError('Empty excerpt')
    fade=min(round(.005*RATE),len(clip)//4)
    clip[:fade]*=np.linspace(0,1,fade)[:,None]
    clip[-fade:]*=np.linspace(1,0,fade)[:,None]
    peak=float(np.max(np.abs(clip)))
    gain=min(1,10**(target_db/20)/max(peak,1e-8))
    clip*=gain
    filename=selection['code']+'.wav';path=WORK/'clips'/filename;path.parent.mkdir(parents=True,exist_ok=True)
    pcm=np.round(np.clip(clip,-1,1)*32767).astype('<i2')
    with wave.open(str(path),'wb') as out:
        out.setnchannels(2);out.setsampwidth(2);out.setframerate(RATE);out.writeframes(pcm.tobytes())
    waveform=np.max(np.abs(clip),axis=1)
    samples=[float(np.max(part)) if len(part) else 0 for part in np.array_split(waveform,64)]
    return dict(selection,source_id=source['id'],author=source['author'],title=source['title'],url=source['url'],
                license=source['license'],license_url=source['license_url'],source_file=source['source_file'],
                file='audio/clips/'+filename,duration=round(len(clip)/RATE,4),
                trim=[round(start/RATE,5),round(end/RATE,5)],gain_db=round(20*np.log10(gain),2),
                peak_time=round(int(np.argmax(np.sum(clip**2,axis=1)))/RATE,4),
                peak_db=round(20*np.log10(max(float(np.max(np.abs(clip))),1e-8)),2),
                waveform=[round(s/max(float(np.max(np.abs(clip))),1e-8),3) for s in samples],
                source_sha256=hashlib.sha256(file.read_bytes()).hexdigest(),sha256=hashlib.sha256(path.read_bytes()).hexdigest())


def main():
    """Produce review metadata and attribution with explicit source timestamps for every candidate."""
    if (WORK/'feedback-round-4.json').exists():
        from forest_enemy_audio_round4 import build_round4
        build_round4()
        return
    if (WORK/'feedback-round-3.json').exists():
        from forest_enemy_audio_round3 import build_round3
        build_round3()
        return
    if (WORK/'round2-plan.json').exists():
        from forest_enemy_audio_round2 import build_round2
        build_round2()
        return
    sources={r['id']:r for r in json.loads((WORK/'research/verified-sources.json').read_text())}
    curated=json.loads((WORK/'curation.json').read_text())
    roles=[];errors=[]
    for ident,selections in curated.items():
        kind,name,state,cue,code,maximum,db=ROLES[ident]
        role={'id':ident,'kind':kind,'name':name,'state':state,'cue_frame':cue,'optional':ident=='bat-wake','candidates':[]}
        for selection in selections:
            try: role['candidates'].append(prepare(sources[str(selection['source'])],selection,maximum,db))
            except ValueError as e: errors.append(f'{selection["code"]} {selection["source"]}: {e}')
        roles.append(role)
    if errors:
        print('\n'.join(errors));raise SystemExit('Review these excerpt timestamps before finishing')
    data={'version':1,'roles':roles,'editing':'trim + 5ms edge fades + gain reduction only; source HQ MP3 retained',
          'auditioned_by_agent':False,'source_count':len({s['source_id'] for r in roles for s in r['candidates']})}
    (WORK/'manifest.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    (WORK.parent/'audio-data.js').write_text('window.FOREST_ENEMY_AUDIO='+json.dumps(data,ensure_ascii=False)+';\n')
    build_previews()
    credits=['Enemy sound candidates · CC0 1.0','Prepared from Freesound HQ MP3 previews. Original downloads may require login.','Only trim, 5ms fades and gain reduction. No pitch shift, time stretch, synthesis, EQ or denoising.','']
    for r in roles:
        for s in r['candidates']:
            credits.append(f'{s["code"]} | {s["label"]} | {s["title"]} by {s["author"]}\n{s["url"]}\nCC0 1.0 | {s["license_url"]}\nSource excerpt {s["trim"]}; gain {s["gain_db"]} dB\n')
    (WORK/'ATTRIBUTION.txt').write_text('\n'.join(credits))
    print(f'{sum(len(r["candidates"]) for r in roles)} clips, {data["source_count"]} unique source recordings; no game resources changed.')


if __name__=='__main__':main()
