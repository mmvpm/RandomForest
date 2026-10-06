"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
const rgb = (r, g, b) => r | (g << 8) | (b << 16);
const channels = color => [color & 255, (color >> 8) & 255, (color >> 16) & 255];
const assets = new Set(["sBorder4", "sBorder4Night", "sStar", "sStarNight", "sTeleportStart", "sTeleportStartNight"]);
const active = new Map();
let draws = [], blend = ["src", "inv", "src", "inv"], pixel = [0.4, 0.5, 0.6, 1], spriteAlpha = 160 / 255;
const imageColors = {sBorder4: [0.6, 0.7, 0.4], sBorder4Night: [0.4, 0.6, 0.9]};

// Model GPU compositing of one identical-alpha sprite pixel using production draw calls.
function draw(sprite, frame, x, y, sx, sy, angle, tint, alpha) {
  draws.push({sprite, frame, x, y, sx, sy, angle, tint, alpha, blend: [...blend]});
  if (!imageColors[sprite]) return;
  const color = imageColors[sprite].map((c, i) => c * channels(tint)[i] / 255);
  const a = spriteAlpha * alpha;
  const factor = name => ({src: a, inv: 1 - a, one: 1, zero: 0})[name];
  pixel = [...color.map((c, i) => c * factor(blend[0]) + pixel[i] * factor(blend[1])),
    a * factor(blend[2]) + pixel[3] * factor(blend[3])];
}

const context = vm.createContext({
  global: {playing_level: 30}, self: {}, room: "game", rMenu: "menu", rLevelSelect: "select", rBlackRoom: "black",
  oMenu: "menuObject", oLevelSelect: "selectObject", oPlayer: {is_dark: true}, noone: -1,
  c_white: rgb(255,255,255), c_black: 0, c_ltgray: rgb(192,192,192), c_dkgray: rgb(128,128,128),
  bm_normal: "normal", bm_src_alpha: "src", bm_inv_src_alpha: "inv", bm_one: "one", bm_zero: "zero",
  round: Math.round, array_create: (n, v) => Array(n).fill(v), array_length: a => a.length,
  array_push: (a, v) => a.push(v), variable_clone: structuredClone,
  variable_global_exists: n => Object.hasOwn(context.global, n), variable_struct_exists: (s, n) => Object.hasOwn(s, n),
  variable_struct_get: (s, n) => s[n], variable_struct_set: (s, n, v) => {s[n] = v;}, variable_struct_get_names: Object.keys,
  make_color_rgb: rgb, color_get_red: c => channels(c)[0], color_get_green: c => channels(c)[1], color_get_blue: c => channels(c)[2],
  instance_exists: obj => active.has(obj), instance_find: obj => active.get(obj),
  funCurrentLevelTheme: () => "night", __funMenuThemeIndex: t => ["day","evening","night","morning"].indexOf(t),
  funLevelTheme: i => i < 20 ? "day" : i < 30 ? "evening" : i < 40 ? "night" : "morning",
  asset_get_index: n => assets.has(n) ? n : -1, sprite_get_name: n => n,
  gpu_get_blendmode_ext_sepalpha: () => [...blend],
  gpu_set_blendmode: () => {blend = ["src","inv","src","inv"];},
  gpu_set_blendmode_ext_sepalpha: (...values) => {blend = Array.isArray(values[0]) ? [...values[0]] : values;},
  draw_sprite_ext: draw,
  draw_sprite_stretched_ext: (s,f,x,y,w,h,t,a) => draw(s,f,x,y,w,h,0,t,a)
});
for (const name of ["scriptLevelThemes", "scriptThemePresentation", "scriptThemeUiDraw"]) {
  let code = fs.readFileSync(path.join(root,"scripts",name,name+".gml"),"utf8");
  code = code.replace(/\band\b/g,"&&").replace(/\bor\b/g,"||");
  vm.runInContext(code, context);
}
context.funCurrentLevelTheme = () => "night";
context.__funMenuThemeIndex = t => ["day","evening","night","morning"].indexOf(t);
context.funLevelTheme = i => i < 20 ? "day" : i < 30 ? "evening" : i < 40 ? "night" : "morning";
const day = context.funThemePalette("day"), night = context.funThemePalette("night");
assert.equal(day.accent, rgb(112,211,112));
assert.equal(day.selected_border, rgb(58,110,58));
assert.equal(day.movement_fx, rgb(125,211,189));
assert.equal(night.accent, rgb(177,169,190));
assert.equal(night.selected_border, rgb(159,148,169));
assert.equal(night.text, rgb(156,163,173));
assert.equal(night.border, rgb(122,113,132));
assert.equal(night.locked_text, rgb(103,109,121));
assert.equal(night.locked_border, rgb(43,47,54));
assert.equal(night.inactive, rgb(44,49,58));
assert.equal(night.panel_muted, rgb(136,143,153));
assert.equal(night.movement_fx, rgb(179,184,240));
for (const t of ["evening","morning"]) assert.deepEqual({...context.funThemePalette(t)}, {...day});
const halfway = context.funThemePresentation("night", [0.5,0,0.5,0]);
assert.deepEqual(channels(halfway.palette.accent), [145,190,151]);

for (const a of [0, 160/255, 1]) {
  for (const opacity of [0.3, 1]) {
    spriteAlpha = a; pixel = [0.4,0.5,0.6,1]; draws = [];
    blend = ["one","inv","zero","one"];
    context.funDrawUiPanel("sBorder4", 0, 10, 20, 90, 40, context.c_white, opacity, halfway);
    const expected = [0.4,0.5,0.6].map((back,i) => back * (1-a*opacity)
      + (imageColors.sBorder4[i]+imageColors.sBorder4Night[i])/2 * a * opacity);
    expected.forEach((v,i) => assert(Math.abs(pixel[i]-v)<1e-12, "RGB fade must preserve one alpha occlusion"));
    assert.deepEqual(blend, ["one","inv","zero","one"], "complete blend restoration");
    assert.equal(draws.length, 3);
    assert(draws.every(d => d.x === 10 && d.y === 20 && d.sx === 90 && d.sy === 40));
  }
}
draws = [];
context.funDrawUiSprite("sStar", 0, 1, 2, 1, 1, 0, context.c_white, 1, context.funThemePresentation("night"));
assert.equal(draws[0].sprite, "sStarNight");
draws = [];
context.funDrawUiPanel("sBorder4",0,1,2,10,20,context.c_white,1,context.funThemePresentation("morning",[0.3,0.2,0,0.5]));
assert.equal(draws.length,1, "identical fallback art must use the exact original primitive");
assets.add("sStarEvening");
delete context.global.theme_asset_cache.sStarEvening;
draws = [];
context.funDrawUiSprite("sStar",0,0,0,1,1,0,context.c_white,1,context.funThemePresentation("evening"));
assert.equal(draws[0].sprite,"sStarEvening");
context.global.theme_palettes.morning.accent = rgb(240,190,150);
assert.equal(context.funThemePresentation("morning").palette.accent,rgb(240,190,150));

context.room = "menu";
active.set(context.oMenu,{menu_background:{target:2,weights:[0.25,0,0.75,0]}});
const overlay = context.funUiScenePresentation();
assert.deepEqual(Array.from(overlay.weights),[0.25,0,0.75,0]);
context.funApplyUiPresentation(overlay);
assert.equal(context.self.current_color,overlay.palette.accent);
context.room = "black";
assert.equal(context.funUiScenePresentation().theme,"night", "results/dialogue use completed level");
active.set(context.oPlayer,context.oPlayer);
context.global.playing_level = 29;
assert.equal(context.funVisualEffectTheme(),"night", "staged dark skin wins inside black room");
context.oPlayer.is_dark = false;
assert.equal(context.funVisualEffectTheme(),"evening");
context.room = "game";
context.self = {sprite_index:"sTeleportStart",image_index:2.5,x:3,y:4,image_xscale:-1,image_yscale:1,image_angle:90,image_blend:context.c_white,image_alpha:0.8,mask_index:7};
draws=[]; context.funDrawThemeEffectSelf();
assert.equal(draws[0].sprite,"sTeleportStartNight");
assert.equal(draws[0].frame,2.5); assert.equal(draws[0].sx,-1);
assert.equal(context.self.sprite_index,"sTeleportStart"); assert.equal(context.self.mask_index,7);
console.log("PASS: original day roles, approved Heather palette, exact alpha crossfades, GPU restoration, scene/skin context, future UI sprites/colours and effect masks");
