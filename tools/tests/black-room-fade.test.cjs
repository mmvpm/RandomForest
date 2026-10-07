"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
let destroyed = false, completions = 0, draws = [], created = [];
const context = vm.createContext({
  self: {}, global: {black_room_context: {scene: {id: "test", fade_seconds: 0.33}}, black_room_seen: {}},
  undefined, min: Math.min, c_black: 0, c_white: 0xffffff, view_camera: ["camera"],
  oFadeIn: "entry", oLevelPassing: "results", musicGame: "music",
  instance_destroy: () => {destroyed = true;},
  camera_get_view_width: () => 480, camera_get_view_height: () => 270,
  draw_set_color() {}, draw_set_alpha() {},
  draw_rectangle: (...args) => {draws.push({alpha: context.self.global_alpha, args});},
  variable_struct_set: (s, n, v) => {s[n] = v;}, funSaveGameState() {}, funStopBlackRoomMusic() {},
  audio_is_playing: () => true, funBlackRoomSetting: (s, n) => s[n],
  instance_create_layer: (x, y, layer, object) => {const instance = {object}; created.push(instance); return instance;},
  instance_create_depth: (x, y, depth, object) => {const instance = {object}; created.push(instance); return instance;}
});

// Execute the actual object event with its GML operators translated.
function event(name) {
  const source = fs.readFileSync(path.join(root, "objects/oFadeOut", name + "_0.gml"), "utf8")
    .replace(/\band\b/g, "&&").replace(/\bor\b/g, "||").replace(/\bexit\b/g, "return");
  vm.runInContext(`(function () {${source}})()`, context);
}

// Story fades retain the opaque endpoint until the GUI has rendered it.
event("Create");
context.self.hold_black_frame = true;
context.self.alpha_step = 0.4;
context.self.end_function = () => {completions++;};
for (let i = 0; i < 3; i++) event("Step");
assert.equal(context.self.global_alpha, 1);
assert.equal(destroyed, false);
event("Step");
assert.equal(completions, 0, "ticks without drawing cannot release the transition");
const gui = fs.readFileSync(path.join(root, "objects/oFadeOut/Draw_64.gml"), "utf8");
vm.runInContext(gui, context);
assert.equal(draws.at(-1).alpha, 1);
assert.deepEqual(draws.at(-1).args, [0, 0, 480, 270, 0]);
event("Step");
assert.equal(destroyed, true);
assert.equal(completions, 1);

// Ordinary fades retain their original completion behavior.
context.self = {}; destroyed = false;
event("Create");
context.self.alpha_step = 1;
context.self.end_function = () => {completions++;};
event("Step");
assert.equal(destroyed, true);
assert.equal(completions, 2);

// Leaving the story room commits the visit, creates results, then creates the reveal.
let flow = fs.readFileSync(path.join(root, "scripts/scriptBlackRoomFlow/scriptBlackRoomFlow.gml"), "utf8")
  .replace(/\band\b/g, "&&").replace(/\bor\b/g, "||");
vm.runInContext(flow, context);
context.funFinishBlackRoomScene();
assert.equal(context.global.black_room_seen.test, true);
assert.deepEqual(created.map(i => i.object), ["results", "entry"]);
assert.equal(created[0].alpha_animation_counter, 0, "results are visible beneath their entry fade");
assert.equal(created[0].border_animation_counter, 0);
assert.equal(created[1].alpha_step, 1 / (60 * 0.33));
console.log("PASS: rendered black endpoint, one callback, ordinary fades and story-to-results reveal");
