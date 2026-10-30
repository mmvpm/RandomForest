/** Exercise production hop completion when physical support differs from planned support. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest/scripts");
let stable = false, ceiling = false, sounds = 0, plans = 0;
const context = vm.createContext({
  noone: -1, room_width: 1200, room_height: 1000, gamespeed_fps: 60,
  sign: Math.sign, abs: Math.abs, min: Math.min, max: Math.max, ceil: Math.ceil, floor: Math.floor,
  game_get_speed: () => 60,
  funEnemyStompKnockbackUpdate() {},
  funEnemyPositionIsDangerous: () => false,
  funForestEnemyPlayLandingSound() { sounds++; },
  funForestEnemyState(state) { context.self.state = state; },
  funForestEnemyTakeDamage: () => false,
  funEnemySeePlayer: () => false,
  instance_place: () => -1, oJumpThru: "jump", oSolid: "solid"
});

// Execute the actual functions, adapting only GML operators and array access syntax.
function run(source) {
  vm.runInContext(source.replace(/\band\b/g, "&&").replace(/\bor\b/g, "||")
    .replace(/\bmod\b/g, "%").replace(/\[\|\s*/g, "["), context);
}
for (const name of ["funEnemyMovement", "scriptForestEnemyMotion", "scriptForestEnemySlime"]) {
  run(fs.readFileSync(path.join(root, name, name + ".gml"), "utf8"));
}
const core = fs.readFileSync(path.join(root, "scriptForestEnemyCore/scriptForestEnemyCore.gml"), "utf8");
run(core.slice(core.indexOf("function funForestEnemyStep("), core.indexOf("function funForestEnemyDraw(")));

// Isolate support geometry while retaining production movement, lifecycle and recovery logic.
context.funEnemyCollidesWithSolid = (x, y) => y > 100 || (ceiling && y < 100);
context.funEnemyOnGroundAt = () => true;
context.funEnemyHasStableSupportAt = () => stable;
context.funForestSlimeSimulateHop = () => { plans++; return undefined; };

// Creates a hop that is resting on the floor, either after flight or before a blocked lift-off.
function reset({centerSupport = false, blocked = false, state = "move"} = {}) {
  stable = centerSupport; ceiling = blocked; sounds = 0; plans = 0;
  context.self = {x: 100, y: 100, bbox_bottom: 99, image_xscale: 1, gravitation: .35,
    current_xspeed: 0, current_yspeed: blocked ? -5.4 : 0,
    sees_player: false, attack_cooldown: 0, hop_phase: "flight", hop_clock: 0,
    forest_kind: "slime", current_direction: 1, air_navigation_active: true,
    air_was_airborne: !blocked, air_target_x: 100, air_target_y: 100, air_move_speed: 1.2,
    was_airborne: true, drop_through_counter: 0, vertical_decision_counter: 0, turn_cooldown: 0,
    state, state_timer: 0, ambient_clock: 0, hurt_countdown_counter: 0, alert_timer: 0, is_dead: false};
}

for (const centerSupport of [false, true]) {
  reset({centerSupport});
  context.funForestSlimeStep();
  assert.equal(context.self.air_navigation_active, false, "physical landing must finish the route");
  assert.equal(context.self.was_airborne, false);
  assert.equal(context.self.hop_phase, "land");
  assert.equal(sounds, 1);
  for (let frame = 0; frame < 120; frame++) context.funForestEnemyStep();
  assert.equal(context.self.hop_phase, "none");
  assert(plans > 0, "a landed hopper must reconsider possible jumps");
  assert.equal(sounds, 1, "resting on an edge must not repeat landing audio");
}

reset({centerSupport: true, blocked: true});
context.funForestSlimeStep();
assert.equal(context.self.air_navigation_active, false, "blocked takeoff must cancel the route");
assert.equal(context.self.was_airborne, false);
assert.equal(context.self.hop_phase, "none");
assert.equal(context.self.turn_cooldown, 12);
assert.equal(sounds, 0, "a hop that never left the floor has no landing cue");
for (let frame = 0; frame < 11; frame++) context.funForestEnemyStep();
assert.equal(plans, 0);
context.funForestEnemyStep();
assert(plans > 0, "retry is available after the existing twelve-frame pause");

for (const state of ["windup", "attack", "recover"]) {
  reset({state});
  context.funForestEnemyMoveGround();
  assert.equal(context.self.state, state, "landing must not interrupt an attack");
  assert.equal(context.self.air_navigation_active, false);
  assert.equal(context.self.was_airborne, false);
  assert.equal(sounds, 1);
  context.self.state = "recover";
  context.self.state_timer = 0;
  context.funForestEnemyStep();
  assert.equal(context.self.state, "idle", "recovery must complete after a real landing");
  assert.equal(context.self.hop_phase, "none");
}

reset();
context.self.forest_kind = "guard";
context.funForestEnemyMoveGround();
assert.equal(context.self.air_navigation_active, true, "other families keep their existing support policy");
assert.equal(sounds, 0);
console.log("PASS: edge/center landings, blocked takeoff, retry, attack recovery and unchanged other families");
