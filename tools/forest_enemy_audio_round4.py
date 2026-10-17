"""Preserve complete gestures and replace damaged endings with actual recorded, naturally decaying tails."""
import copy
import hashlib
import json

import numpy as np

from forest_enemy_audio import RATE, WORK, decode
from forest_enemy_audio_preview import build_previews
from forest_enemy_audio_round2 import credits, fade_tail, read_clip, write_clip
from forest_enemy_audio_round3 import attenuation_curve
from research_forest_enemy_audio import source


def excerpt(ident, cut, code, label, gain_db=0):
    """Read the explicit source interval without auto-trimming its decay or changing its speed."""
    recording = source(str(ident), 'round-4')
    decoded = decode(WORK/recording['source_file'])
    start = round(cut[0]*RATE)
    end = min(len(decoded), round(cut[1]*RATE))
    samples = decoded[start:end].copy() * 10**(gain_db/20)
    metadata = dict(recording, source_id=recording['id'], code=code, label=label,
                    trim=[round(start/RATE,5),round(end/RATE,5)], gain_db=round(gain_db,3))
    metadata['source_sha256'] = hashlib.sha256((WORK/recording['source_file']).read_bytes()).hexdigest()
    return samples, metadata


def natural_candidate(ident, cut, code, label, origin):
    """Keep one complete gesture and use edge fades only after its recorded tail is already quiet."""
    samples, metadata = excerpt(ident,cut,code,label)
    # All comparison levels are reductions from physical recordings, not normalization of a damaged tail.
    factor = float(min(1,10**(-33/20)/float(np.max(np.abs(samples)))))
    samples *= factor
    count = min(round(.003*RATE),len(samples))
    samples[:count] *= np.linspace(0,1,count)[:,None]
    fade_tail(samples,12)
    metadata.update(gain_db=round(20*np.log10(factor),3), tag='Другой вариант',
                    fade_out_ms=12, natural_gesture=True, comparison_origin=origin,
                    edit_note=f'{origin}. Сохранены целое движение и записанное затухание. '
                              'Только снижение уровня и края 3/12 мс на уже тихом окончании.')
    return write_clip(samples,metadata,bits=24)


def join_natural_tail(head, tail_samples, tail_metadata, start, overlap, code, label, note):
    """Crossfade into a real complete release rather than forcing the audible body down to silence."""
    original = read_clip(head)
    at = round(start*RATE)
    count = round(overlap*RATE)
    reference = original[at:at+round(.03*RATE)]
    entrance = tail_samples[:round(.03*RATE)]
    factor = min(1,np.sqrt(np.mean(reference**2))/max(np.sqrt(np.mean(entrance**2)),1e-10))
    # A replacement ending must never become louder than the selected sound's existing peak.
    factor = float(min(factor,.85*np.max(np.abs(original))/max(np.max(np.abs(tail_samples)),1e-10)))
    tail_samples = tail_samples*factor
    tail_metadata = dict(tail_metadata, code=code+'-tail', label='Записанный хвост',
                         gain_db=round(tail_metadata['gain_db']+20*np.log10(factor),3),
                         part_label='Естественный хвост', offset=start)
    tail = write_clip(tail_samples,tail_metadata,bits=24)
    length = at+len(tail_samples)
    combined = np.zeros((length,2))
    combined[:at] = original[:at]
    phase = np.linspace(0,np.pi,count)
    weight = ((1-np.cos(phase))/2)[:,None]
    combined[at:at+count] = original[at:at+count]*(1-weight)+tail_samples[:count]*weight
    combined[at+count:] = tail_samples[count:]
    body = dict(head, part_label='Исходный налёт' if head['code'].startswith('МН') else 'Исходный шелест',
                offset=0, used_interval=[0,round((at+count)/RATE,5)])
    metadata = dict(head, code=code, label=label, tag='Доработка 3', parent_code=head['code'],
                    components=[body,tail], edit_note=note, composition='crossfade to a complete recorded natural release',
                    crossfade={'start':start,'duration':overlap}, fade_out_ms=0)
    metadata.pop('gain_envelope',None)
    metadata.pop('full_timeline',None)
    return write_clip(combined,metadata,bits=24)


def build_round4():
    """Apply the fourth review without modifying any earlier candidate or approved sound."""
    archives = [json.loads((WORK.parent/f'revisions/before-feedback-round-{n}/audio/manifest.json').read_text())
                for n in (2,3,4)]
    originals = {clip['code']:clip for archive in archives for role in archive['roles'] for clip in role['candidates']}
    previous = archives[-1]
    feedback = {row['action']:row for row in json.loads((WORK/'feedback-round-4.json').read_text())['selections']}
    # This exact released air is already accepted in ЖВ08. Its real decay replaces the cloth recoil.
    tail_source = originals['ЖВ08']
    tail_samples = read_clip(tail_source)[round(.20*RATE):]
    tail_metadata = dict(tail_source,trim=[round(tail_source['trim'][0]+.20,5),tail_source['trim'][1]],
                         part_label='Воздушный хвост принятого ЖВ08')
    bat = join_natural_tail(originals['МН04Р'],tail_samples,tail_metadata,.105,.06,'МН04Р3',
                            'Налёт · с цельным воздушным хвостом',
                            'Основной налёт МН04Р сохранён. Вместо возвратного движения ткани — реальное '
                            'затухание принятого ЖВ08, соединённое переходом 60 мс. Никакой реверберации, '
                            'растяжения, синтеза или искусственно добавленной тишины.')
    # A quiet late section of the same cloth recording has a complete release and no further gesture.
    wake_samples,wake_metadata = excerpt('391448',[7.09,7.40],'МП01Р3-tail','Естественный хвост ткани')
    fade_tail(wake_samples,160)
    wake_metadata['fade_out_ms'] = 160
    wake = join_natural_tail(originals['МП01Р2'],wake_samples,wake_metadata,.18,.05,'МП01Р3',
                             'Отлипание · с записанным мягким окончанием',
                             'Начальный тихий шелест МП01Р2 сохранён без усиления. Окончание переходит '
                             'за 50 мс в записанное затухание ткани. Хлопок не возвращён; шум, реверберация '
                             'и растяжение не добавлялись. Полная длина около 0,49 с.')
    guard_source = originals['СЗ03']
    guard_samples = read_clip(guard_source)
    knots = [(0,1),(.14,1),(.17,.5),(.205,.06),(.25,.04),(.35,.02),(len(guard_samples)/RATE,0)]
    guard = write_clip(guard_samples*attenuation_curve(len(guard_samples),knots)[:,None],
                       dict(guard_source,code='СЗ03Р3',label='Хруст · всё переплетение, без позднего мусора',
                            tag='Доработка 3',parent_code='СЗ03',gain_envelope=knots,
                            edit_note='Первые 140 мс, включая всё переплетение щелчков, сохранены побайтно. '
                                      'Обрабатывается только поздний мусор после естественного затухания хруста.'),bits=24)
    slam = copy.deepcopy(feedback['sweeper-slam']['components'][0])
    slam.update(code='ЖУ24Р',label='Широкий бамбук · только взмах',tag='По выбору',parent_code='ЖУ24-air',
                edit_note='Точная звуковая часть ЖУ24-air: удар ЖУ02 удалён полностью. Сам взмах не обработан.')
    slam.pop('offset',None)
    candidates = [
        ('855768',[.09046,.64469],'МН11','Плавный деревянный пролёт','Из принятого ЖВ08'),
        ('422503',[0,.326],'МН12','Сдержанный проход посоха','Из ЖВ07'),
        ('855733',[0,.46592],'МН13','Воздушный свист деревянного груза','Из СС08'),
        ('371313',[5.155,5.72],'МН14','Дуга тонкого удилища','Из ЖВ10, с полным окончанием'),
        ('855844',[.01485,.49179],'МН15','Протяжённый проход бамбука','Из ЖВ02'),
        ('427979',[10.245,10.60],'МН16','Компактный пролёт с естественным затуханием','Из ЖВ09'),
        ('742905',[.23,.65],'МН17','Мягкий одиночный воздушный срез','Новая запись: взмах перфорированной лопаткой'),
        ('389170',[0,.56],'МН18','Хлопковая ткань · один проход','Новая запись: cotton fabric swooshing through air'),
        ('711122',[22.14,22.68],'МН19','Широкий мягкий проход ткани','Новая запись: отдельный жест ткани, не серия взмахов'),
        ('60030',[0,.43684],'МН20','Воздушный проход тонкого бамбука','Новая запись: Swosh / Whoosh / Air Cut')]
    alternatives = [natural_candidate(*spec) for spec in candidates]
    changes = {
        'bat-attack':(['МН04Р',bat,*alternatives],'МН04Р3: реальное затухание вместо срезанного хвоста. Рядом исходный МН04Р и ровно десять других вариантов — четыре новых записи и шесть из других действий.'),
        'guard-impact':(['СЗ03',guard,'СЗ08'],'СЗ03Р3: начальное переплетение полностью сохранено. Убран только поздний мусор; первые 140 мс не изменены.'),
        'bat-wake':(['МП01Р2',wake],'МП01Р3: тот же тихий начальный шелест с полным записанным окончанием; без усиления и хлопка.'),
        'sweeper-slam':([slam],'ЖУ24Р — только выбранный широкий бамбук. Удара ЖУ02 больше нет.')}
    roles = []
    for initial in previous['roles']:
        role = copy.deepcopy(initial)
        row = feedback[role['id']]
        role.update(feedback_note=row['note'],previous_choice=row['code'],
                    feedback_history=[*role.get('feedback_history',[]),role.get('feedback_note','')])
        if role['id'] in changes:
            entries,summary = changes[role['id']]
            role.update(review_status='compare',review_summary=summary,candidates=[])
            for entry in entries:
                if isinstance(entry,str):
                    clip = copy.deepcopy(originals[entry]);clip['tag'] = 'Запасной' if entry=='СЗ08' else 'Для сравнения'
                else:
                    clip = entry
                role['candidates'].append(clip)
            if role['id']=='sweeper-slam':
                role['cue_frame'] = 3
                role['previous_choice'] = 'ЖУ24Р'
        else:
            chosen = copy.deepcopy(originals[row['code']]);chosen['tag'] = 'Утверждён'
            role.update(review_status='ready',review_summary=f'{chosen["code"]} принят и сохранён без изменений.',candidates=[chosen])
        roles.append(role)
    recordings = {part['source_id'] for role in roles for clip in role['candidates'] for part in clip.get('components',[clip])}
    manifest = dict(version=2,round=4,roles=roles,source_count=len(recordings),reference_page_volume=.25,
                    auditioned_by_agent=False,editing='whole physical gestures and recorded natural releases; preserve braided crack')
    (WORK/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    (WORK.parent/'audio-data.js').write_text('window.FOREST_ENEMY_AUDIO='+json.dumps(manifest,ensure_ascii=False)+';\n')
    credits(manifest)
    build_previews()
    print(f'Round 4: {sum(len(role["candidates"]) for role in roles)} candidates; ten other bat attacks.')


if __name__ == '__main__':
    build_round4()
