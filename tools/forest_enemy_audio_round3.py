"""Apply the second listening feedback while preserving approved sounds and complete recorded tails."""
import copy
import json

import numpy as np

from forest_enemy_audio import RATE, WORK
from forest_enemy_audio_preview import build_previews
from forest_enemy_audio_round2 import credits, read_clip, revise, write_clip

ARCHIVES = [WORK.parent / f'revisions/before-feedback-round-{number}/audio/manifest.json'
            for number in (2, 3)]


def attenuation_curve(length, knots):
    """Interpolate attenuation with zero-slope joins; never cut, amplify or stretch a recording."""
    times = np.arange(length) / RATE
    result = np.ones(length)
    for (start, first), (end, last) in zip(knots, knots[1:]):
        inside = (times >= start) & (times <= end)
        phase = (times[inside] - start) / (end - start)
        result[inside] = first + (last - first) * (1 - np.cos(np.pi * phase)) / 2
    result[-1] = knots[-1][1]
    return result


def smooth_recording(original, code, label, knots, note):
    """Remove secondary gestures with a smooth gain envelope while retaining the full original timeline."""
    samples = read_clip(original)
    knots = [(0, 1), *knots, (len(samples) / RATE, 0)]
    envelope = attenuation_curve(len(samples), knots)
    metadata = dict(original, code=code, label=label, tag='Доработка 2',
                    parent_code=original['code'], relative_gain=1, gain_envelope=knots,
                    full_timeline=True, edit_note=note)
    return write_clip(samples * envelope[:, None], metadata)


def slam_variant(originals, code, air_code, factor, label):
    """Pair a firmer earlier swing with the exact approved ЖУ02 impact, preserving both source timings."""
    air = copy.deepcopy(originals[air_code])
    air_samples = read_clip(air) * factor
    air.update(code=code+'-air', label='Взмах · '+air_code, relative_gain=factor,
               parent_code=air_code, gain_db=round(air['gain_db'] + 20*np.log10(factor), 2))
    air = write_clip(air_samples, air)
    hit = copy.deepcopy(originals['ЖУ02'])
    air['offset'] = round(max(0, .17-air['peak_time']), 5)
    hit['offset'] = round(.42-hit['peak_time'], 5)
    parts = [(air, read_clip(air)), (hit, read_clip(hit))]
    length = max(round(part['offset']*RATE)+len(samples) for part, samples in parts)
    combined = np.zeros((length, 2))
    for part, samples in parts:
        offset = round(part['offset']*RATE)
        combined[offset:offset+len(samples)] += samples
    metadata = dict(hit, code=code, label=label, tag='Новый взмах',
                    components=[air, hit], sync_time=.42,
                    edit_note=f'Взмах {air_code}, уровень ×{factor:g}. Затем ЖУ02 с прежней громкостью и полным хвостом. '
                              'Без изменения высоты, скорости и тембра.',
                    composition='firmer physical swing followed by the unchanged ЖУ02 impact')
    metadata.pop('offset', None)
    return write_clip(combined, metadata)


def build_round3():
    """Publish only accepted references and the requested third listening comparisons."""
    archives = [json.loads(path.read_text()) for path in ARCHIVES]
    originals = {clip['code']: clip for archive in archives for role in archive['roles'] for clip in role['candidates']}
    previous = archives[-1]
    feedback = {row['action']: row for row in json.loads((WORK/'feedback-round-3.json').read_text())['selections']}
    bat = smooth_recording(originals['МН04Р'], 'МН04Р2', 'Налёт · один проход, плавный хвост',
                           [(.125,1),(.145,.7),(.16,.2),(.175,.045),(.24,.045),(.30,.02)],
                           'Громкость выбранного МН04Р сохранена. Вторичные движения после основного налёта '
                           'плавно подавлены. Полная длительность 375 мс сохранена; обрезки нет.')
    guard = smooth_recording(originals['СЗ03'], 'СЗ03Р2', 'Хруст · сглаженный второй всплеск',
                             [(.035,1),(.043,.6),(.05,.5),(.06,.08),(.065,.20),(.075,.23),
                              (.085,.4),(.105,.65),(.14,.9),(.17,.5),(.205,.06),(.25,.04),(.35,.02)],
                             'Второй всплеск на 55–70 мс подавлен плавной огибающей. '
                             'Первый удар и весь исходный хвост 441 мс сохранены. Конец не отрезан.')
    wake = smooth_recording(originals['МП01'], 'МП01Р2', 'Отлипание · прежний уровень, полный хвост',
                            [(.195,1),(.21,.10),(.225,.018),(.24,.007),(.255,.009),
                             (.27,.015),(.285,.025),(.31,.035),(.33,.06),(.39,.08)],
                            'Взят МП01 на первоначальном уровне, без усиления ×6 из прошлой доработки. '
                            'Заключительный хлопок подавлен плавно. Полный исходный хвост 460 мс сохранён; '
                            'ни один фрагмент не усилен и не обрезан.')
    shot = revise(originals, dict(code='СС07Р2', **{'from':'СС07Р'}, gain=.5,
                                 label='Выпуск семени · ещё вдвое тише',
                                 edit_note='Ещё ×0,5 (−6,02 дБ) относительно выбранного СС07Р. '
                                           'Итого ×0,35 относительно первого СС07. Тембр и длина прежние.'))
    slams = [slam_variant(originals, *spec) for spec in [
        ('ЖУ21','ЖВ03',.70,'Сильный посох → ЖУ02'),
        ('ЖУ22','ЖВ05',.75,'Плотный прут → ЖУ02'),
        ('ЖУ23','ЖВ06',.80,'Деревянный взмах → ЖУ02'),
        ('ЖУ24','ЖВ01',.80,'Широкий бамбук → ЖУ02')]]
    selections = {
        'bat-attack':(['МН04','МН04Р',bat], 'Третий вариант МН04Р2: вторичные движения подавлены, основной налёт и полная длина сохранены.'),
        'guard-shot':(['СС07Р',shot], 'СС07Р2 ещё вдвое тише выбранного СС07Р: −6,02 дБ без других изменений.'),
        'guard-impact':(['СЗ03',guard,'СЗ08'], 'СЗ03Р2 сохраняет полную длину. Второй всплеск сглажен огибающей; неудачная короткая СЗ03Р убрана.'),
        'sweeper-slam':(['ЖУ02',*slams], 'ЖУ02 оставлен неизменным. Четыре взмаха из прежней подборки плотнее прошлых; у всех один и тот же удар ЖУ02.'),
        'bat-wake':(['МП01','МП01Р',wake], 'МП01Р2: первоначальный уровень, подавленный хлопок и полный плавный хвост. МП01Р оставлен для сравнения.')}
    roles = []
    for initial in previous['roles']:
        role = copy.deepcopy(initial)
        row = feedback[role['id']]
        role.update(feedback_note=row['note'], previous_choice=row['code'],
                    feedback_history=[*role.get('feedback_history', []), role.get('feedback_note','')])
        if role['id'] in selections:
            entries, summary = selections[role['id']]
            role.update(review_status='compare', review_summary=summary)
            role['candidates'] = []
            for entry in entries:
                if isinstance(entry,str):
                    clip = copy.deepcopy(originals[entry])
                    clip['tag'] = 'Запасной' if clip['code']=='СЗ08' else 'Для сравнения'
                else:
                    clip = entry
                role['candidates'].append(clip)
        else:
            chosen = copy.deepcopy(originals[row['code']])
            chosen['tag'] = 'Утверждён'
            role.update(review_status='ready', review_summary=f'{chosen["code"]} выбран без новых замечаний; сохранён без изменений.', candidates=[chosen])
        roles.append(role)
    recordings = {part['source_id'] for role in roles for clip in role['candidates'] for part in clip.get('components',[clip])}
    manifest = dict(version=2, round=3, roles=roles, source_count=len(recordings),
                    reference_page_volume=.25, auditioned_by_agent=False,
                    editing='full-timeline smooth attenuation of secondary gestures; firmer library swings with unchanged ЖУ02')
    (WORK/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    (WORK.parent/'audio-data.js').write_text('window.FOREST_ENEMY_AUDIO='+json.dumps(manifest,ensure_ascii=False)+';\n')
    credits(manifest)
    build_previews()
    print(f'Round 3: {sum(len(role["candidates"]) for role in roles)} candidates; five accepted actions preserved.')


if __name__ == '__main__':
    build_round3()
