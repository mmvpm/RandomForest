/** Check authored branches, numeric substitutions, the final gate and stomp rings. */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../../RandomForest');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const config = JSON.parse(read('datafiles/narrative/black_room.json'));
let waves = [], saves = 0;
const context = vm.createContext({
  self: {}, global: {black_room_config: config, black_room_context: undefined,
    black_room_seen: Object.fromEntries(config.scenes.map(s => [s.id, false])),
    ending_stage: 0, lost_clones: 127, current_level: 40,
    orange_firefly_records: Array(41).fill(false),
    campaign_levels_config: JSON.parse(read('datafiles/narrative/levels.json'))},
  array_length: a => a.length, array_create: (n, v) => Array(n).fill(v),
  array_push: (a, v) => a.push(v),
  array_copy: (a, dest, b, src, count) => {a.splice(dest, count, ...b.slice(src, src + count));},
  variable_struct_get: (s, k) => s[k], variable_struct_exists: (s, k) => Object.hasOwn(s, k),
  variable_struct_set: (s, k, v) => {s[k] = v;},
  variable_global_exists: k => Object.hasOwn(context.global, k),
  json_parse: JSON.parse, funReadGeneratedLevelFile: file => read('datafiles/' + file),
  string: String, string_replace_all: (s, a, b) => s.replaceAll(a, b),
  oPlayerStompWave: 'wave', instance_number: () => waves.length, instance_find: (o, i) => waves[i],
  point_distance: (x, y, xx, yy) => Math.hypot(x - xx, y - yy),
  funSaveGameState: () => {saves++;}
});

/** Evaluate production functions with only GML's spelling of operators translated. */
function load(name) {
  vm.runInContext(read(`scripts/${name}/${name}.gml`).replace(/^#macro DIALOGUE_ELLIPSIS_DELAY_SECONDS (.+)$/gm, 'const DIALOGUE_ELLIPSIS_DELAY_SECONDS = $1;').replace(/^#macro.*$/gm, '')
    .replace(/\band\b/g, '&&').replace(/\bor\b/g, '||'), context);
}
for (const name of ['scriptBlackRoomDialogue', 'scriptDialogueText', 'scriptCampaignLevels',
  'funOrangeFireflyProgress', 'scriptStoryProgress', 'scriptBlackRoomConfig', 'scriptPlayerStompWave']) load(name);

/** Read one actual filtered monologue at a selected count. */
function lines(level, count) {
  const scene = config.scenes.find(s => s.after_level === level);
  return context.funLoadBlackRoomLines(scene, {after_level: level, collected: count, records: []});
}
for (const count of [0, 2, 3, 7, 8, 9]) {
  const text = lines(9, count).map(l => l.text);
  assert.equal(text.includes('Похоже, ни капли!'), count <= 2);
  assert.equal(text.includes('Так, некоторый прогресс есть... Это вселяет надежду'), count >= 3 && count <= 7);
  assert.equal(text.includes('Вижу, что да... И весьма неплохо!'), count >= 8);
  assert.equal(text.includes('Однажды...'), count >= 3);
}
for (const count of [0, 10, 11, 31, 32]) {
  const text = lines(32, count).map(l => l.text);
  assert.equal(text.includes('Неужели ты не хочешь понять?'), count <= 10);
  assert.equal(text.includes('Вижу, ты на правильном пути'), count >= 11);
  assert.equal(text.some(t => t.startsWith('Но этого недостаточно...')), count >= 11 && count <= 31);
  assert.equal(text.includes('Так держать!'), count === 32);
}
for (const count of [0, 39, 40]) {
  const text = lines(40, count).map(l => l.text);
  assert.equal(text.includes('Вернись назад и собери оставшееся'), count < 40);
  assert.equal(text.includes('Путь открыт'), count === 40);
  assert(text.indexOf('Для снятия нажмите Пробел') < text.indexOf('Впереди остался последний шаг'));
}
assert.equal(context.funExpandDialogueText('[orange]{collected}[/orange] / {deaths}',
  {collected: 17, deaths: 127}), '[orange]17[/orange] / 127');
assert.equal(context.funBlackRoomProgress(23).deaths, 127);

assert.equal(context.funStoryLevelUnlocked(40), false);
context.global.black_room_seen.ck_after_40 = true;
assert.equal(context.funStoryLevelUnlocked(40), true);
assert.equal(context.funStoryLevelCanEnter(40), false);
context.global.orange_firefly_records.fill(true, 0, 39);
assert.equal(context.funStoryLevelCanEnter(40), false);
context.global.orange_firefly_records[39] = true;
assert.equal(context.funStoryLevelCanEnter(40), true);
context.global.ending_stage = 2;
context.global.orange_firefly_records.fill(false);
assert.equal(context.funStoryLevelCanEnter(40), true);
assert.equal(context.funFindBlackRoomScene(0), undefined);
context.funRecordLostClone();
assert.equal(context.global.lost_clones, 128);
assert.equal(saves, 1);

waves = [{x: 0, y: 0, previous_radius: 40, radius: 42}];
assert.equal(context.funFireflyHitByStomp({x: 43, y: 0}, 2), true);
assert.equal(context.funFireflyHitByStomp({x: 37, y: 0}, 2), false);
assert.equal(context.funFireflyHitByStomp({x: 45, y: 0}, 2), false);
waves = [{x: 0, y: 0, previous_radius: 82, radius: 84}];
assert.equal(context.funFireflyHitByStomp({x: 86, y: 0}, 3), true);
assert.equal(context.funFireflyHitByStomp({x: 88, y: 0}, 3), false);

// Round-trip actual persistence, then execute startup routing for every ending stage.
const ini = new Map();
Object.assign(context, {
  ini_open() {}, ini_close() {}, funSaveWallMemoryReadState() {},
  funLoadWallMemoryReadState: () => ({}), funGetLevelsCount: () => 41,
  ini_write_real: (section, key, value) => ini.set(section + ':' + key, value),
  ini_read_real: (section, key, fallback) => ini.get(section + ':' + key) ?? fallback,
  floor: Math.floor, clamp: (v, a, b) => Math.max(a, Math.min(b, v))
});
load('funSaveGameState');
load('funLoadGameState');
context.global.ending_stage = 1;
context.global.special_level_completed = true;
context.global.orange_firefly_records.fill(true, 0, 40);
context.funSaveGameState();
context.global.ending_stage = 0;
context.global.lost_clones = 0;
context.global.orange_firefly_records.fill(false);
context.funLoadGameState();
assert.equal(context.global.ending_stage, 1);
assert.equal(context.global.lost_clones, 128);
assert.equal(context.funGetOrangeFireflyCount(), 40, 'prank keeps every collected memory');
let route;
Object.assign(context, {
  alarm: [], rMenu: 'menu', window_center() {},
  room_goto: room => {route = room;},
  funOpenStoryEnding: real => {route = real ? 'true' : 'finale';}
});
const startup = read('objects/oLoading/Alarm_0.gml').replace(/\band\b/g, '&&').replace(/\bor\b/g, '||');
for (const [stage, completed, expected] of [[0, false, 'menu'], [0, true, 'finale'], [1, true, 'true'], [2, true, 'menu']]) {
  context.global.ending_stage = stage;
  context.global.special_level_completed = completed;
  vm.runInContext(startup, context);
  assert.equal(route, expected, `startup at ending stage ${stage}`);
}

// When the author's private source is present, require exact punctuation and ordering.
const plotPath = path.resolve(root, '../.temp/plot.md');
if (fs.existsSync(plotPath)) {
  const sections = fs.readFileSync(plotPath, 'utf8').split('---')[0].split(/^### /m).slice(1);
  for (const section of sections) {
    const [heading, ...body] = section.split('\n');
    const number = heading.match(/После уровня (\d+)/)?.[1];
    const file = number ? `ck_after_${number}` : heading.trim() === 'Финал' ? 'ck_after_41' : 'true_ending';
    const expected = body.map(s => s.trim()).filter(s => s && !s.startsWith('//') && !/^\d+-\d+:?$/.test(s))
      .map(s => s.replace(/^\[(Система|Она)\] /, '').replace(/[{}]/g, '')
        // The author's in-game wording intentionally differs from the private draft here.
        .replace('Решил чуть потроллить :)', 'Решил чутка потроллить :)'));
    const actual = JSON.parse(read(`datafiles/narrative/dialogues/${file}.json`)).lines.map(l => l.text
      .replaceAll('[orange]', '').replaceAll('[/orange]', '')
      .replaceAll('{collected}', '(число-собранных-ОС)').replaceAll('{deaths}', '(число-смертей)'));
    assert.deepEqual(actual, expected, `verbatim authored lines: ${heading}`);
    let condition;
    const metadata = [];
    for (const raw of body) {
      const text = raw.trim();
      if (!text || text.startsWith('//')) continue;
      const branch = text.match(/^(\d+)-(\d+):?$/);
      if (branch) { condition = {min_collected: +branch[1], max_collected: +branch[2]}; continue; }
      if (!/^\s/.test(raw)) condition = undefined;
      const speaker = text.match(/^\[(Система|Она)\] /)?.[1] ?? 'Голос';
      metadata.push({speaker, when: condition});
    }
    const stored = JSON.parse(read(`datafiles/narrative/dialogues/${file}.json`)).lines;
    assert.deepEqual(stored.map(l => ({speaker:l.speaker ?? 'Голос', when:l.when})), metadata,
      `authored speakers and inclusive conditions: ${heading}`);
  }
}
console.log('PASS: verbatim plot, ordered conditional branches, numbers, 39/40 gate, replay, saved losses and stomp ring/body boundaries');
