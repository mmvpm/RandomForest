"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
const assets = new Set(["sBackground_x13", "sBackground", "sBackgroundEvening_x13", "sBackgroundNight_x13", "sBackgroundMorning_x13",
  "sBackgroundEvening", "sBackgroundNight", "sBackgroundMorning", "sSlimeIdle", "sSlimeIdleNight", "tsPlatforms", "tsPlatformsNight"]);
let nextSurface = 1, alive = new Set(), draws = [], gpuMode = "normal", filtering = false, lookupCount = 0;
const context = vm.createContext({
  self: {}, global: {playing_level: 0}, room: "generated", rGeneratedLevel: "generated", noone: -1,
  funGetRoomIndex: () => -1, view_camera: [0], c_black: 0, c_white: 255, bm_add: "add", bm_normal: "normal",
  min: Math.min, max: Math.max, clamp: (n, low, high) => Math.max(low, Math.min(high, n)),
  lerp: (a, b, t) => a + (b - a) * t, choose: (...values) => values[0], random_range: (low, high) => (low + high) / 2,
  array_create: (count, value) => Array(count).fill(value), array_length: a => a.length, variable_clone: structuredClone,
  variable_global_exists: name => Object.hasOwn(context.global, name),
  variable_struct_exists: (struct, name) => Object.hasOwn(struct, name), variable_struct_get: (s, n) => s[n],
  variable_struct_set: (s, n, v) => { s[n] = v; },
  asset_get_index: name => { lookupCount++; return assets.has(name) ? name : -1; },
  sprite_get_name: name => name, tileset_get_name: name => name,
  sprite_get_width: () => 624, sprite_get_height: () => 351,
  sBackground_x13: "sBackground_x13", camera_get_view_width: () => 480, camera_get_view_height: () => 270,
  surface_exists: id => alive.has(id), surface_create: () => { const id = nextSurface++; alive.add(id); return id; },
  surface_free: id => { assert(alive.delete(id), "double surface free"); }, surface_set_target() {}, surface_reset_target() {},
  draw_clear_alpha() {}, draw_set_color() {}, draw_set_alpha: alpha => { context.drawAlpha = alpha; },
  draw_rectangle() {}, draw_sprite() {}, gpu_set_tex_filter: value => { filtering = value; },
  gpu_set_blendmode: value => { gpuMode = value; },
  funBlurSurface: () => context.surface_create(),
  draw_surface: (surface, x, y) => { assert(alive.has(surface)); draws.push({surface, x, y, alpha: context.drawAlpha, gpuMode}); },
  draw_sprite_ext: (...values) => { context.lastSpriteDraw = values; },
  layer_get_id: name => name, layer_tilemap_get_id: name => name,
  tilemap_get_tileset: () => "tsPlatforms", tilemap_tileset: (map, sprite) => { context.lastTileset = sprite; }
});

// Execute the production GML; only translate its boolean operators.
for (const name of ["scriptLevelThemes", "scriptMenuBackground"]) {
  const source = fs.readFileSync(path.join(root, "scripts", name, name + ".gml"), "utf8");
  vm.runInContext(source.replace(/\band\b/g, "&&").replace(/\bor\b/g, "||"), context);
}

for (const [index, theme] of [[0, "day"], [19, "day"], [20, "evening"], [29, "evening"], [30, "night"], [39, "night"], [40, "morning"]]) {
  assert.equal(context.funLevelTheme(index), theme);
  assert.notEqual(context.funThemeBackground(theme), -1);
  assert.notEqual(context.funThemeBackground(theme, false), -1);
}
assert.equal(context.funThemeSprite("sSlimeIdle", "night"), "sSlimeIdleNight");
const previousLookups = lookupCount;
context.funThemeSprite("sSlimeIdle", "night");
assert.equal(lookupCount, previousLookups, "variant lookup must be cached");
for (const theme of ["day", "morning", "evening"]) {
  assert.equal(context.funThemeSprite("sSlimeIdle", theme), "sSlimeIdle");
  assert.equal(context.funThemeTileset("tsPlatforms", theme), "tsPlatforms");
}
assets.add("sSlimeMoveEvening");
assert.equal(context.funThemeSprite("sSlimeMove", "evening"), "sSlimeMoveEvening", "optional future sibling");
context.funApplyRoomTheme("night");
assert.equal(context.lastTileset, "tsPlatformsNight");
context.global.playing_level = 30;
context.self = {sprite_index: "sSlimeIdle", image_index: 2.5, x: 24, y: 40, image_xscale: -0.8, image_yscale: 0.8,
  image_angle: 0, image_blend: 91, image_alpha: 0.4, mask_index: "original_mask"};
context.funDrawThemedSelf(1.2, 0.75);
assert.deepEqual(Array.from(context.lastSpriteDraw), ["sSlimeIdleNight", 2.5, 24, 40, -0.96, 0.6000000000000001, 0, 91, 0.4]);
assert.equal(context.self.sprite_index, "sSlimeIdle");
assert.equal(context.self.mask_index, "original_mask");
context.funGetRoomIndex = () => 0;
assert.equal(context.funCurrentLevelTheme(), "day", "authored direct launch beats stale global index");

context.self = {};
context.funMenuBackgroundCreate(20);
let state = context.self.menu_background;
assert.deepEqual(Array.from(state.weights), [0, 1, 0, 0]);
context.funMenuBackgroundSetTheme("night");
for (let frame = 0; frame < 10; frame++) context.funMenuBackgroundStep();
const mixture = Array.from(state.weights), oldX = state.x;
context.funMenuBackgroundSetTheme("morning");
assert.deepEqual(Array.from(state.weights), mixture, "rapid retarget must not jump");
context.funMenuBackgroundStep();
assert.notEqual(state.x, oldX, "crossfade must not reset or stop camera drift");
assert(Math.abs(state.weights.reduce((a, b) => a + b, 0) - 1) < 1e-12);
context.funMenuBackgroundDraw();
assert.equal(alive.size, 3, "only visible theme surfaces stay cached");
assert(draws.every(draw => draw.gpuMode === "add" && draw.x === -state.x && draw.y === -state.y));
assert(Math.abs(draws.reduce((total, draw) => total + draw.alpha, 0) - 1) < 1e-12, "no brightness dip");
assert.equal(gpuMode, "normal");
assert.equal(filtering, false);
alive.clear(); draws = [];
context.funMenuBackgroundDraw();
assert.equal(alive.size, 3, "lost surfaces recover automatically");
context.funMenuBackgroundCleanup();
assert.equal(alive.size, 0);
context.global.menu_background_handoff = true;
context.self = {};
context.funMenuBackgroundCreate(30);
assert.deepEqual(Array.from(context.self.menu_background.weights), Array.from(state.weights));
assert.equal(context.self.menu_background.x, state.x);
assert.equal(context.self.menu_background.target, 2);
for (let frame = 0; frame < 30; frame++) context.funMenuBackgroundStep();
assert.deepEqual(Array.from(context.self.menu_background.weights), [0, 0, 1, 0]);
context.funMenuBackgroundCleanup();
context.self = {};
context.funMenuBackgroundCreate(40);
assert.deepEqual(Array.from(context.self.menu_background.weights), [0, 0, 0, 1], "gameplay entry immediately uses current theme");
state = context.self.menu_background;
state.x = state.max_x; state.vx = 0.1;
context.funMenuBackgroundStep();
assert.equal(state.x, state.max_x);
assert.equal(state.vx, -0.1);
context.funMenuBackgroundSetTheme("morning");
assert.equal(state.frame, 30, "same-theme pages do not restart fades");
console.log("PASS: theme boundaries, future variants/fallback, masks and drawing, interrupted crossfades, menu handoff, drift, GPU recovery and cleanup");
