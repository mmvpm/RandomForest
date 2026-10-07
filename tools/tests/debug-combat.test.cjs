"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
const config = JSON.parse(read("datafiles/narrative/black_room.json"));
let swords = [], saved = 0;
const context = vm.createContext({
  self: {}, oPlayer: "player", soundCoinCollecting: "coin",
  oPlayerSword: "sword", soundPlayerAttack1: "attack1", soundPlayerAttack2: "attack2", soundPlayerAttack3: "attack3",
  global: {is_debug: false, campaign_abilities_config: JSON.parse(read("datafiles/narrative/abilities.json")),
    black_room_config: config, black_room_seen: Object.fromEntries(config.scenes.map(s => [s.id, false])),
    black_room_context: undefined},
  max: Math.max, clamp: (v, lo, hi) => Math.max(lo, Math.min(hi, v)),
  variable_clone: structuredClone, array_length: a => a.length,
  variable_struct_get: (s, n) => s[n], variable_struct_get_names: Object.keys,
  variable_struct_set: (s, n, v) => {s[n] = v;},
  instance_create_depth: () => { const sword = {}; swords.push(sword); return sword; },
  audio_play_sound() {}, keyboard_check_pressed: () => false,
  ord: s => s.charCodeAt(0), string_ord_at: () => 0, string_length: s => s.length,
  funSaveGameState: () => {saved++;}
});

// Read the production source so combat checks exercise the actual implementation.
function read(file) { return fs.readFileSync(path.join(root, file), "utf8"); }

// Translate only the GML operators used by these scripts and the debug event.
function translate(code) {
  return code.replace(/\band\b/g, "&&").replace(/\bor\b/g, "||")
    .replace("with (oPlayer) {", "{");
}
for (const name of ["scriptCampaignAbilities", "scriptPlayerAbilities", "scriptPlayerAttackState"]) {
  vm.runInContext(translate(read(`scripts/${name}/${name}.gml`)), context);
}

// Execute the real password toggle on the current player instance.
function toggleDebug() {
  Object.assign(context.self, {frame_counter: 0, debug_password: "DEBUG", debug_current_index: 6});
  vm.runInContext(`(function () {${translate(read("objects/oDebug/Step_0.gml"))}})()`, context);
}

// Compare both combat states before and after every saved campaign milestone.
for (const allRewards of [false, true]) {
  context.global.black_room_seen = Object.fromEntries(config.scenes.map(s => [s.id, allRewards]));
  for (const debug of [false, true]) {
    context.global.is_debug = debug;
    const abilities = context.funCampaignAbilities();
    assert.equal(abilities.max_health, debug ? 10 : allRewards ? 6 : 2);
    assert.equal(abilities.stomp_damage, debug ? 7 : allRewards ? 2 : 1);
    assert.equal(Boolean(abilities.stomp), allRewards, "debug does not unlock stomp");
    assert.equal(Boolean(abilities.double_jump), allRewards, "debug does not unlock double jump");
    context.self = {health: 1, x: 10, y: 20};
    context.funPlayerRefreshAbilities();
    assert.equal(context.self.health, 1, "ability refresh does not heal");
    for (const attack of [1, 2, 3]) {
      context.self.attack_animation_type = attack;
      context.funPlayerCreateAttackSword();
      assert.equal(swords.at(-1).damage, debug ? 7 : (attack === 3 ? 3 : 2) + Number(allRewards));
    }
  }
}

context.global.black_room_seen = Object.fromEntries(config.scenes.map(s => [s.id, false]));
context.global.is_debug = false;
context.self = {health: 1};
toggleDebug();
assert.equal(context.global.is_debug, true);
assert.equal(context.self.max_health, 10);
assert.equal(context.self.health, 10);
assert.equal(context.self.stomp_damage, 7);
const healthReward = config.scenes.find(s => s.id === "ck_after_09");
context.global.black_room_context = {scene: healthReward, reward_staged: true};
context.funPlayerRefreshAbilities();
assert.equal(context.self.max_health, 10, "staged health reward cannot overwrite debug");
toggleDebug();
assert.equal(context.self.max_health, 3);
assert.equal(context.self.health, 3);
assert.equal(context.self.stomp_damage, 1);
assert.equal(saved, 2, "both toggle states are persisted");

// A fresh player starts with all ten HP, just as the production Create event does.
context.global.is_debug = true;
context.self = {health: context.funCampaignAbilities().max_health};
context.funPlayerRefreshAbilities();
assert.equal(context.self.health, 10);
assert.match(read("scripts/funLoadGameState/funLoadGameState.gml"), /ini_read_real\("general", "is_debug", 0\) != 0/);
assert.match(read("scripts/funSaveGameState/funSaveGameState.gml"), /ini_write_real\("general", "is_debug", global.is_debug\)/);
assert.match(read("objects/oPlayerTapSword/Create_0.gml"), /self.damage = 1/);
console.log("PASS: debug HP, all combo hits, both stomp upgrades, staged rewards, live toggle, persistence and unchanged unlocks/throw");
