/** Execute result cadence, level-00 records and ending routes from production GML. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
const read = file => fs.readFileSync(path.join(root, file), "utf8");
let frame = 0, sounds = [], fade = false, pressed = false, route, saved;
const c = vm.createContext({
  self: {}, global: {}, noone: -1, LEVEL_SELECT_PAGE_SIZE: 10,
  max: Math.max, min: Math.min, clamp: (v, a, b) => Math.max(a, Math.min(b, v)),
  array_length: a => a.length, array_create: (n, v) => Array(n).fill(v),
  array_push: (a, v) => a.push(v), is_array: Array.isArray,
  variable_struct_exists: (s, k) => Object.hasOwn(s, k),
  variable_global_exists: k => Object.hasOwn(c.global, k),
  funApplyUiPresentation() {}, funThemePresentation() {}, funLevelTheme() {},
  instance_deactivate_all() {}, instance_activate_object() {},
  instance_exists: object => object === "fade" && fade,
  keyboard_check_pressed: key => key === "enter" && pressed,
  mouse_check_button_pressed: () => false, mouse_x: 0, mouse_y: 0,
  camera_get_view_x: () => 0, camera_get_view_y: () => 0, view_camera: [0],
  funGetButtonByMouse: () => -1,
  audio_play_sound: () => sounds.push({frame, reward: c.self.current_reward}),
  funGetLevelsCount: () => 41,
  funSaveGameState: () => { saved = JSON.parse(JSON.stringify(c.global)); },
  funMenuOpenLevelSelect: () => { route = "select"; },
  funFindBlackRoomScene: () => undefined,
  funOpenStoryEnding: () => { route = "finale"; },
  instance_create_layer: () => { route = "results"; },
  room_goto: room => { route = room; },
  ...Object.fromEntries(["sBorder4", "oWeatherAudio", "oDebug", "oFullscreen", "oLevelPassing",
    "soundStarCollecting", "soundMenuButton"].map(x => [x, x])),
  oFadeIn: "fade", vk_enter: "enter", vk_down: "down", vk_up: "up", mb_left: "left",
  oTimeCounter: {time_counter: 600},
});

/** Translate operator spelling, leaving the actual algorithms and event bodies intact. */
function translate(source) {
  return source.replace(/^#macro.*$/gm, "").replace(/\band\b/g, "&&")
    .replace(/\bor\b/g, "||").replace(/\bdiv\b/g, "/").replace(/\bexit\b/g, "return;");
}
/** Load one production script into the shared test VM. */
function load(name) { vm.runInContext(translate(read(`scripts/${name}/${name}.gml`)), c); }
/** Execute one real object event with its own local variables. */
function event(name) {
  vm.runInContext(`(function(){${translate(read(`objects/oLevelPassing/${name}_0.gml`))}})()`, c);
}
load("funGetStarCount");
load("funGetLevelStarTimes");
load("scriptCampaignLevels");
load("funAchievementProgress");
load("funAchievementRun");
load("funUpdateTimeRecord");
load("scriptBlackRoomFlow");
c.global.campaign_levels_config = JSON.parse(read("datafiles/narrative/levels.json"));

// Every combination, including records already earned, must keep new rewards 30 frames apart.
for (let before = 0; before <= 3; before++) for (let stars = before; stars <= 3; stars++) {
  for (const enemies of [false, true]) for (const flawless of [false, true]) {
    frame = 0; sounds = []; pressed = false; fade = false; c.self = {};
    c.global.playing_level = 0;
    c.global.last_completion_result = {current_time: 600, best_time: 600,
      stars_before: before, stars_after: stars, enemy_clear_before: false,
      enemy_clear_after: enemies, flawless_before: false, flawless_after: flawless,
      new_enemy_clear: enemies, new_flawless: flawless};
    event("Create");
    for (frame = 0; frame < 240; frame++) event("Step");
    const expected = [...Array(stars - before).fill(0), ...(enemies ? [1] : []), ...(flawless ? [2] : [])];
    assert.deepEqual(sounds.map(x => x.reward), expected);
    for (let i = 1; i < sounds.length; i++) assert.equal(sounds[i].frame - sounds[i - 1].frame, 30);
    assert.equal(c.self.shown_stars, stars);
    assert.equal(c.self.enemy_badge_t, Number(enemies));
    assert.equal(c.self.flawless_badge_t, Number(flawless));
  }
}
// Black fades stop the entire sequence; skipping reveals everything without layered audio.
c.global.last_completion_result = {current_time: 600, best_time: 600,
  stars_before: 0, stars_after: 3, enemy_clear_before: false, enemy_clear_after: true,
  flawless_before: false, flawless_after: true, new_enemy_clear: true, new_flawless: true};
c.self = {}; sounds = []; event("Create"); fade = true;
for (frame = 0; frame < 120; frame++) event("Step");
assert.equal(c.self.stats_animation_counter, 60);
fade = false; pressed = true; event("Step"); pressed = false;
assert.equal(c.self.shown_stars, 3); assert.equal(c.self.flawless_badge_t, 1);
assert.equal(sounds.length, 0);

// Exercise real portal completion; 00 earns records but cannot affect campaign page totals.
Object.assign(c.global, {playing_level: 40, current_level: 40, ending_stage: 0,
  playing_level_star_times: {three_stars: 20, two_stars: 40},
  time_records: Array(41).fill(-1), enemy_clear_records: Array(41).fill(false),
  flawless_records: Array(41).fill(false), orange_firefly_records: Array(41).fill(false)});
c.funBeginAchievementRun(); assert.equal(c.global.current_run_flawless, true);
c.funMarkAchievementDamage(); assert.equal(c.global.current_run_flawless, false);
c.funBeginAchievementRun();
c.funAreAllCombatEnemiesDefeated = () => true;
const door = read("objects/oDoor/Step_0.gml");
vm.runInContext(translate(door.slice(door.indexOf("function __funCompleteLevel"), door.indexOf("// on collision"))), c);
c.__funCompleteLevel();
assert.equal(saved.time_records[40], 600);
assert.equal(saved.enemy_clear_records[40], true);
assert.equal(saved.flawless_records[40], true);
assert.equal(saved.special_level_completed, true);
assert.equal(saved.last_completion_result.stars_after, 3);
assert.equal(c.funGetAchievementPageProgress(4, 10).levels_count, 0);
assert.equal(c.funGetAchievementPageProgress(4, 10).max_stars, 0);
assert.equal(c.funGetAchievementPageProgress(3, 10, Array(41).fill({three_stars:20,two_stars:40})).max_stars, 30);
c.funShowCompletedLevel(); assert.equal(route, "finale");
c.global.ending_stage = 2; c.funShowCompletedLevel(); assert.equal(route, "results");
c.oTimeCounter.time_counter = 900; c.global.current_run_flawless = false;
c.funAreAllCombatEnemiesDefeated = () => false;
c.__funCompleteLevel();
assert.equal(saved.time_records[40], 600);
assert.equal(saved.flawless_records[40], true);
assert.equal(saved.last_completion_result.new_flawless, false);
vm.runInContext(translate(read("objects/oLevelPassing/Step_0.gml").split("// Story results wait")[0]), c);
c.__funContinueLevel(); assert.equal(route, "select");
// Round-trip the real save/load functions: 00 records survive both ending stages.
const ini = new Map();
Object.assign(c, {string: String, floor: Math.floor,
  ini_open() {}, ini_close() {}, funSaveWallMemoryReadState() {}, funLoadWallMemoryReadState: () => ({}),
  variable_struct_get: (s,k) => s[k], variable_struct_set: (s,k,v) => {s[k]=v;},
  ini_write_real: (section,key,value) => ini.set(section+":"+key,value),
  ini_read_real: (section,key,fallback) => ini.get(section+":"+key) ?? fallback});
c.global.black_room_config = JSON.parse(read("datafiles/narrative/black_room.json"));
c.global.black_room_seen = Object.fromEntries(c.global.black_room_config.scenes.map(s => [s.id,true]));
load("funSaveGameState"); load("funLoadGameState");
for (const stage of [0,1,2]) {
  c.global.ending_stage = stage; c.funSaveGameState();
  c.global.time_records = []; c.global.enemy_clear_records = []; c.global.flawless_records = [];
  c.funLoadGameState();
  assert.equal(c.global.time_records[40],600);
  assert.equal(c.global.enemy_clear_records[40],true);
  assert.equal(c.global.flawless_records[40],true);
  assert.equal(c.global.special_level_completed,true);
  assert.equal(c.global.ending_stage,stage);
}
console.log("PASS: ordered rewards at uniform 30-frame intervals, skipping/fades, 00 records, page isolation and first/replay routing");
