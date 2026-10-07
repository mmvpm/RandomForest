"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
const config = JSON.parse(read("datafiles/narrative/black_room.json"));
let pressed = new Set(), pauseExists = true, destroyed = false, saved;
let soundCount = 0, shakeCount = 0, waveCount = 0;
const context = vm.createContext({
  self: {}, other: {}, noone: -1, vk_space: "space", vk_enter: "enter",
  oPlayer: {}, oPauseMenu: {paused: false}, oFadeIn: "fade", oDialogue: "dialogue",
  oLevelPassing: "results", oPlayerStompWave: "wave", musicGame: "music", gamespeed_fps: 0,
  soundPlayerStompImpact: "impact", funCameraShake: () => { shakeCount++; },
  player_states: {idle: 0, move: 1, fall: 2, stomp: 3, story_transform: 4,
    attack: 5, teleport: 6, hurt: 7, die: 8},
  global: {key_pause: "escape", playing_level: 30, music_enabled: false,
    campaign_abilities_config: JSON.parse(read("datafiles/narrative/abilities.json")),
    black_room_config: config, black_room_seen: {}},
  min: Math.min, max: Math.max, round: Math.round, floor: Math.floor,
  ceil: Math.ceil, clamp: (v, lo, hi) => Math.max(lo, Math.min(hi, v)),
  variable_clone: structuredClone, array_length: a => a.length,
  variable_struct_get: (s, key) => s[key], variable_struct_get_names: Object.keys,
  variable_struct_set: (s, key, value) => { s[key] = value; },
  keyboard_check_pressed: key => pressed.has(key),
  instance_exists: object => object === context.oPauseMenu && pauseExists,
  instance_destroy: () => { destroyed = true; },
  instance_create_depth: (x, y, depth, object) => { if (object === "wave") waveCount++; return {}; }, instance_create_layer: () => ({}),
  audio_stop_sound() {}, audio_play_sound: sound => { if (sound === "impact") soundCount++; }, audio_is_playing: () => true,
  game_get_speed: () => 60, sprite_get_speed: () => 100 / 7,
  funLoadBlackRoomLines: () => [{text: "Test"}],
  funBlackRoomSetting: (scene, key) => scene[key] ?? config.defaults[key] ?? undefined,
  funPlayerStartTransformFx() {}, funPlayerStopTransformFx() {},
  funPlayerTransformBlocked: () => false, funPlayerDetectCriticalState: () => undefined,
  funPlayerCollideWithSolid: () => false,
  funSaveGameState: () => { saved = JSON.stringify(context.global.black_room_seen); }
});

// Read production code rather than maintaining a duplicate of its conditions.
function read(file) {
  return fs.readFileSync(path.join(root, file), "utf8");
}

// Reproduce GML instance scope for bound callbacks and the controller's with statements.
function scoped(owner, action) {
  const previous = context.self, previousOther = context.other;
  context.self = owner;
  context.other = previous;
  try { return action(); }
  finally { context.self = previous; context.other = previousOther; }
}
context.method = (owner, action) => () => scoped(owner, action);
context.scoped = scoped;

// Translate the limited GML syntax used by these production events to JavaScript.
function translate(source) {
  return source.replace(/\band\b/g, "&&").replace(/\bor\b/g, "||")
    .replace(/\[\|\s*/g, "[")
    .replace(/\bexit\b/g, "return")
    .replace("with (oPlayer) funPlayerRefreshAbilities()",
      "scoped(oPlayer, () => funPlayerRefreshAbilities())")
    .replace(/with \(oPlayer\) started = ([\s\S]*?other\.finish_transform\))/,
      "started = scoped(oPlayer, () => $1)")
    .replace(/with \(dialogue\) \{([\s\S]*?)\}/, "scoped(dialogue, () => {$1})");
}

// Load real scripts and register their sprite names as opaque test resources.
function load(name) {
  const source = read(`scripts/${name}/${name}.gml`);
  for (const sprite of source.match(/\bs[A-Z]\w*/g) || []) context[sprite] = sprite;
  vm.runInContext(translate(source), context);
}
for (const name of ["funPlayerChangeState", "scriptCampaignAbilities", "scriptPlayerAbilities",
  "scriptPlayerTransform", "scriptBlackRoomFlow", "scriptDialoguePlayback"]) load(name);
context.funPlayerTransformBlocked = () => false;

// Run a production object event with its owning instance as self.
function event(object, name, owner) {
  return scoped(owner, () => vm.runInContext(
    `(function () {\n${translate(read(`objects/${object}/${name}_0.gml`))}\n})()`, context));
}

// Start either transformation scene with its actual controller Create callback bindings.
function scene(afterLevel) {
  const definition = config.scenes.find(s => s.after_level === afterLevel);
  context.global.playing_level = afterLevel;
  context.global.black_room_seen = Object.fromEntries(config.scenes.map(s => [s.id, false]));
  context.global.black_room_seen.ck_after_26 = true;
  context.global.black_room_seen.ck_after_30 = afterLevel === 40;
  context.global.black_room_context = {scene: definition, progress: {},
    current_dark: afterLevel === 40, health: 2, max_health: 4, reward_staged: false};
  context.oPlayer = {state: context.player_states.idle, is_on_ground: true,
    is_dark: afterLevel === 40, x: 108, y: 264, depth: 100,
    image_xscale: 1, image_yscale: 1, stomp_recovery_counter: 0,
    story_pending: false, story_transform_used: false, transform_complete: undefined};
  pressed = new Set();
  pauseExists = true;
  context.oPauseMenu.paused = false;
  const controller = {};
  event("oBlackRoomController", "Create", controller);
  controller.dialogue_started = true;
  return controller;
}

// Finish the final dialogue page using the real Enter handler and completion callback.
function finishDialogue(controller) {
  const dialogue = {ready: true, pages: [{glyphs: ["T"]}], page_index: 0,
    revealed: 1, typing_speed: 30, lines: [{text: "Test"}], line_index: 0,
    end_function: controller.finish_dialogue};
  destroyed = false;
  pressed = new Set(["enter"]);
  event("oDialogue", "Step", dialogue);
  assert.equal(destroyed, true);
  assert.equal(controller.dialogue_finished, true);
  assert.equal(controller.portal_ready, false);
  assert.equal(context.oPlayer.story_pending, true);
  pressed.clear();
}

for (const afterLevel of [30, 40]) {
  const controller = scene(afterLevel), player = context.oPlayer;
  pressed = new Set(["space"]);
  event("oBlackRoomController", "Step", controller);
  assert.equal(controller.transform_running, false, "no transform before dialogue ends");
  finishDialogue(controller);
  pressed = new Set(["space"]);
  event("oBlackRoomController", "Step", controller);
  assert.equal(controller.transform_running, true, "closed pause object must not block Space");
  assert.equal(player.state, context.player_states.story_transform);
  const completion = player.transform_complete;
  soundCount = 0; shakeCount = 0; waveCount = 0;
  event("oBlackRoomController", "Step", controller);
  assert.equal(player.transform_complete, completion, "repeat presses cannot restart transformation");
  scoped(player, () => context.funPlayerTransformStart());
  for (let tick = 0; tick < 200 && !controller.portal_ready; tick++) {
    scoped(player, () => context.funPlayerTransformLogic());
  }
  assert.equal(soundCount, 1, "one landing sound per story transformation");
  assert.equal(shakeCount, 1, "one landing shake per story transformation");
  assert.equal(waveCount, 0, "story transformation causes no combat wave");
  assert.equal(controller.portal_ready, true);
  assert.equal(controller.transform_running, false);
  assert.equal(player.is_dark, afterLevel === 30);
  assert.equal(player.story_pending, false);
  assert.equal(context.funCampaignPlayerIsDark(), afterLevel === 30);
  context.funFinishBlackRoomScene();
  context.global.black_room_seen = JSON.parse(saved);
  context.global.black_room_context = undefined;
  assert.equal(context.funCampaignPlayerIsDark(), afterLevel === 30, "skin persists after portal exit");
}

// Guard inputs on pause entry/exit regardless of which instance handles its Step first.
for (const pauseState of [false, true]) {
  for (const escapePressed of [false, true]) {
    const controller = scene(30);
    finishDialogue(controller);
    context.oPauseMenu.paused = pauseState;
    pressed = new Set(escapePressed ? ["space", "escape"] : ["space"]);
    event("oBlackRoomController", "Step", controller);
    assert.equal(controller.transform_running, !pauseState && !escapePressed);
  }
}

// Airborne or incompatible actions reject the request without locking out retries.
for (const state of ["idle", "move", "attack", "stomp", "hurt", "die", "teleport", "story_transform"]) {
  for (const grounded of [false, true]) {
    const controller = scene(30);
    finishDialogue(controller);
    context.oPlayer.state = context.player_states[state];
    context.oPlayer.is_on_ground = grounded;
    pressed = new Set(["space"]);
    event("oBlackRoomController", "Step", controller);
    assert.equal(controller.transform_running, grounded && ["idle", "move"].includes(state));
  }
}
const controller = scene(30);
finishDialogue(controller);
pauseExists = false;
pressed = new Set(["space"]);
event("oBlackRoomController", "Step", controller);
assert.equal(controller.transform_running, true, "missing pause object is safe");
scoped(context.oPlayer, () => context.funPlayerTransformStart());
const player = context.oPlayer;
const progress = player.transform_progress;
scoped(player, () => context.funPlayerTransformAbort());
assert.equal(controller.transform_running, true, "story action cannot be cancelled");
assert.equal(player.state, context.player_states.story_transform);
assert.equal(player.transform_progress, progress);
context.funPlayerDetectCriticalState = () => context.player_states.hurt;
context.funPlayerTransformBlocked = () => true;
for (let tick = 0; tick < 200 && !controller.portal_ready; tick++) {
  scoped(player, () => context.funPlayerTransformLogic());
}
assert.equal(controller.portal_ready, true, "an accepted story action always completes");
pressed = new Set(["space"]);
event("oBlackRoomController", "Step", controller);
assert.equal(controller.transform_running, false, "completed story action never restarts");
assert.equal(scoped(player, () => context.funPlayerBeginStoryTransform(false, () => {})), false);

// A blocked trajectory is rejected before the one-shot action is consumed.
const blockedController = scene(30);
finishDialogue(blockedController);
pressed = new Set(["space"]);
event("oBlackRoomController", "Step", blockedController);
assert.equal(blockedController.transform_running, false);
assert.equal(context.oPlayer.story_transform_used, false);
context.funPlayerTransformBlocked = () => false;
event("oBlackRoomController", "Step", blockedController);
assert.equal(blockedController.transform_running, true);
console.log("Black room: both one-shot transformations, landing sound/shake, no damage wave, pause guards, trajectory preflight, non-interruption and saved skin passed.");
