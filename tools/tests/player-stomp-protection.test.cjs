"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
let enemies = [], waves = [], trapped = false, blocked = false, impacts = 0;
let soundCount = 0, shakeCount = 0, fps = 60;
const context = vm.createContext({
  self: {}, noone: -1, undefined,
  min: Math.min, max: Math.max, abs: Math.abs, sign: Math.sign,
  ceil: Math.ceil, floor: Math.floor, round: Math.round, sqrt: Math.sqrt,
  clamp: (value, low, high) => Math.max(low, Math.min(high, value)),
  lerp: (a, b, t) => a + (b - a) * t, array_create: size => Array(size),
  point_distance: (x, y, a, b) => Math.hypot(a - x, b - y),
  ds_list_create: () => [], ds_list_destroy() {},
  ds_list_add: (list, value) => list.push(value),
  ds_list_find_index: (list, value) => list.indexOf(value),
  oTrap: "trap", oEnemy: "enemy", oSolid: "solid", oJumpThru: "jump_thru",
  oPlayerSword: "player_sword", oPlayerStompWave: "wave",
  oPlayer: {x: 100},
  player_states: {idle: 0, fall: 1, hurt: 2, stomp: 3, story_transform: 4,
    attack: 5, teleport: 6, die: 7},
  bungalo_states: {hurt: 1, die: 2}, skeleton_states: {hurt: 1, die: 2},
  slime_states: {hurt: 1, die: 2, attack: 3, move: 4, idle: 5},
  gamespeed_fps: 0, game_get_speed: () => fps,
  sprite_get_speed: () => 100 / 7,
  global: {campaign_abilities_config: {stomp_cooldown_seconds: 9}},
  place_meeting: (x, y, object) => object === "trap" && trapped,
  instance_place: () => ({damage: 2}),
  instance_place_list: (x, y, object, list) => {
    list.push(...enemies); return list.length;
  },
  instance_number: () => waves.length, instance_find: (object, i) => waves[i],
  instance_create_depth: (x, y) => {
    impacts++;
    const wave = {x, y, radius: 0, previous_radius: 0, hit_enemies: []};
    waves.push(wave); return wave;
  },
  collision_rectangle_list: () => 0,
  funPlayerCollideWithSolid: () => false,
  funPlayerStartTransformFx() {}, funPlayerStopTransformFx() {},
  funShowDamageText() {}, funSlimeDetectState: () => undefined,
  funSkeletonWantAttack: () => false,
  funDefaultStepMove: () => { context.self.x += context.self.current_xspeed; },
  funCameraShake: () => { shakeCount++; },
  audio_play_sound: () => { soundCount++; }, soundPlayerStompImpact: "impact",
  funReadInputs() {}, funPlayerHandleTapSword: () => false,
  funPlayerIdleStart() {}, funPlayerIdleLogic() {}
});

// Execute the production GML, translating only GML operators to JavaScript.
function translate(source) {
  return source.replace(/\band\b/g, "&&").replace(/\bor\b/g, "||")
    .replace(/\[\|\s*/g, "[");
}
function load(name) {
  const source = fs.readFileSync(path.join(root, "scripts", name, name + ".gml"), "utf8");
  for (const sprite of source.match(/\bs[A-Z]\w*/g) || []) context[sprite] = sprite;
  vm.runInContext(translate(source), context);
}
for (const name of ["funPlayerChangeState", "scriptPlayerAbilities", "scriptPlayerTransform",
  "funPlayerDetectCriticalState", "scriptPlayerStompWave", "funEnemyMovement",
  "scriptEnemyStompKnockback", "funBungaloDetectCriticalState",
  "funSkeletonDetectCriticalState", "funSlimeDetectCriticalState",
  "scriptBungaloHurtState", "scriptSkeletonHurtState", "scriptSlimeHurtState",
  "scriptBungaloAttackState", "scriptSkeletonAttackState"]) load(name);
context.funPlayerTransformBlocked = () => blocked;
context.funDefaultChangeState = state => { context.self.state = state; };

// Keep a real damaging overlap present throughout takeoff, landing and recovery.
function player(isDark = false) {
  context.self = {x: 100, y: 200, image_xscale: 1, image_yscale: 1,
    depth: 0, state: context.player_states.stomp, is_dark: isDark, health: 2,
    hurt_countdown_counter: 0, stomp_recovery_counter: 0, stomp_radius: 60,
    key_attack_pressed: false, key_stomp_pressed: false, is_on_ground: true,
    transform_cancel: undefined};
  context.funPlayerTransformStart();
  return context.self;
}
enemies = [{x: 100, damage: 1, can_damage_player: true, is_dead: false}];
for (const isDark of [false, true]) {
  const p = player(isDark);
  for (const frame of [0, 10, 11, 12, 23, 24, 25, 37]) {
    p.image_index = frame;
    assert.equal(context.funPlayerDetectCriticalState(), frame < 11 ? 2 : undefined);
    trapped = true;
    assert.equal(context.funPlayerDetectCriticalState(), frame < 11 ? 2 : undefined);
    trapped = false;
  }
  p.state = context.player_states.story_transform;
  assert.equal(context.funPlayerDetectCriticalState(), context.player_states.hurt);
}
let p = player();
context.funPlayerTransformLogic();
assert.equal(p.state, context.player_states.hurt, "damage can interrupt crouching");
assert.equal(impacts, 0);

// Advance across the exact takeoff boundary with an enemy overlapping the body.
for (const isDark of [false, true]) {
  p = player(isDark);
  p.image_index = 10;
  p.transform_progress = 11 - (100 / 7) / fps / 2;
  context.funPlayerTransformLogic();
  assert.equal(p.image_index, 11);
  assert.equal(p.state, context.player_states.stomp);
  while (p.state === context.player_states.stomp) context.funPlayerTransformLogic();
  assert.equal(p.health, 2);
  assert.equal(p.state, context.player_states.idle);
  assert.equal(p.stomp_recovery_counter, 12);
  assert.equal(context.funPlayerDetectCriticalState(), undefined);
  const step = "(function () {\n" + translate(fs.readFileSync(
    path.join(root, "objects/oPlayer/Step_0.gml"), "utf8")) + "\n})();";
  for (let tick = 0; tick < 11; tick++) vm.runInContext(step, context);
  assert.equal(context.funPlayerDetectCriticalState(), undefined);
  vm.runInContext(step, context);
  assert.equal(context.funPlayerDetectCriticalState(), context.player_states.hurt);
}
assert.equal(impacts, 2, "one landing wave per stomp");
assert.equal(soundCount, 2);
assert.equal(shakeCount, 2);

// A blocked airborne action loses protection immediately and emits no impact.
p = player(); p.image_index = 17; p.transform_progress = 17;
blocked = true;
context.funPlayerTransformLogic(); blocked = false;
assert.equal(p.state, context.player_states.fall);
assert.equal(p.stomp_recovery_counter, 0);
assert.equal(context.funPlayerDetectCriticalState(), context.player_states.hurt);
assert.equal(impacts, 2);

// Wave damage interrupts each enemy type and drives their actual hurt movement.
for (const kind of ["Slime", "Skeleton", "Bungalo"]) {
  for (const direction of [-1, 1]) {
    for (const frameRate of [30, 60, 120]) {
      fps = frameRate;
      const enemy = context.self = {id: 11, x: 100 + direction * 6, y: 200,
        bbox_left: 95, bbox_right: 105, bbox_top: 180, bbox_bottom: 199,
        image_xscale: -direction, health: 6, future_damage: 0,
        hurt_countdown_counter: 0, hurt_countdown: 30, hurt_ximpulse: 0.5,
        hurt_animation_ended: false, current_xspeed: 0};
      context.funEnemyInitializeMovement("mask");
      waves = [{x: 100, y: 200, previous_radius: 0, radius: 2, hit_enemies: []}];
      assert.equal(context[`fun${kind}DetectCriticalState`](), 1);
      context[`fun${kind}HurtStart`]();
      assert.equal(enemy.health, 5);
      assert.equal(enemy.stomp_knockback_direction, 0);
      assert.equal(context.funPlayerStompWaveDamage(), context.noone, "one hit per wave");
      const startX = enemy.x;
      for (let tick = 0; tick < Math.ceil(0.2 * fps); tick++) context[`fun${kind}HurtLogic`]();
      assert.equal(enemy.x - startX, direction * 18);
      assert.equal(enemy.current_xspeed, 0);
      assert.equal(enemy.health, 5);
    }
  }
  // Ordinary damage retains each enemy's existing movement and invulnerability.
  const enemy = context.self = {x: 100, image_xscale: 1, health: 6, future_damage: 2,
    hurt_countdown: 30, hurt_ximpulse: 0.5, current_xspeed: 0};
  context.funEnemyInitializeMovement("mask");
  context[`fun${kind}HurtStart`]();
  assert.equal(enemy.health, 4);
  assert.equal(enemy.current_xspeed, kind === "Slime" ? -0.5 : 0);
  context.funEnemyStompKnockbackUpdate();
  assert.equal(enemy.current_xspeed, kind === "Slime" ? -0.5 : 0);
}
// An enemy exactly at the wave center still gets pushed in a definite direction.
context.self = {id: 12, x: 100, image_xscale: 1,
  bbox_left: 96, bbox_right: 104, bbox_top: 190, bbox_bottom: 199};
waves = [{x: 100, y: 200, previous_radius: 0, radius: 2, hit_enemies: []}];
assert.notEqual(context.funPlayerStompWaveDamage(), context.noone);
assert.equal(context.self.stomp_knockback_direction, -1);

// Landing damage cancels an attacking enemy's owned sword before hurt begins.
context.instance_exists = instance => instance !== -1 && instance.alive;
context.instance_destroy = instance => { instance.alive = false; };
for (const kind of ["Skeleton", "Bungalo"]) {
  const sword = {alive: true};
  context.self = {id: 20, x: 106, y: 200, image_xscale: -1,
    bbox_left: 100, bbox_right: 111, bbox_top: 176, bbox_bottom: 199,
    current_xspeed: 0, hurt_countdown_counter: 0, sword_id: sword};
  context.funEnemyInitializeMovement("mask");
  waves = [{x: 100, y: 200, previous_radius: 0, radius: 2, hit_enemies: []}];
  context[`fun${kind}AttackLogic`]();
  assert.equal(context.self.state, 1);
  assert.equal(sword.alive, false, "stomp interrupts the owned enemy attack");
  assert.equal(context.self.stomp_knockback_direction, 1);
}

// Run production movement against a wall: the push cannot cross solid geometry.
load("funDefaultStepMove");
context.funEnemyCollidesWithSolid = (x, y) => x > 110 || y > 200;
fps = 60;
context.self = {x: 109, y: 200, current_yspeed: 0, gravitation: 0.5,
  drop_through_counter: 0, stomp_knockback_direction: 1};
context.funEnemyStompKnockbackStart();
for (let tick = 0; tick < 12; tick++) {
  context.funDefaultStepMove();
  context.funEnemyStompKnockbackUpdate();
  assert(context.self.x <= 110);
}
assert.equal(context.self.current_xspeed, 0);
console.log("Production GML: both skins, crouch/takeoff/landing/recovery, damage overlaps, cancellation, three enemy types, attack interruption, wall collision, one wave hit and unchanged sword hurt passed.");
