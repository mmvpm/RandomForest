"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.join(__dirname, "../..");
const settings = JSON.parse(fs.readFileSync(path.join(root, "RandomForest/datafiles/narrative/wall_memories.json")));
let saves = 0, cues = 0;
const pressed = new Set();
const context = vm.createContext({
  global: { wall_memory_config: settings, wall_memory_read: {}, key_move_left: "left",
    key_move_right: "right", key_jump: "jump", key_fall: "drop" },
  max: Math.max, min: Math.min, soundWallMemoryReveal: 1, funCurrentLevelTheme: () => "day",
  audio_play_sound() { cues++; }, funSaveGameState() { saves++; },
  variable_struct_exists: (object, key) => Object.hasOwn(object, key),
  variable_struct_get: (object, key) => object[key],
  variable_struct_set: (object, key, value) => { object[key] = value; },
  oTimeCounter: { may_count: false }, instance_exists: object => Boolean(object),
  keyboard_check: key => pressed.has(key)
});
// Execute the actual state-machine functions after translating GML boolean operators.
function load(name, end) {
  let code = fs.readFileSync(path.join(root, `RandomForest/scripts/${name}/${name}.gml`), "utf8");
  if (end) code = code.slice(0, code.indexOf(end));
  code = code.replace(/\band\b/g, "&&").replace(/\bor\b/g, "||").replace(/\bmod\b/g, "%");
  vm.runInContext(code, context);
}
load("scriptWallMemoryProgress");
load("scriptWallMemoryFlow", "/// Activates the nearest unread");
const controller = { movement_started: false };
pressed.add("left");
assert(!context.funWallMemoryMovementStarted(controller));
context.oTimeCounter.may_count = true;
pressed.clear(); pressed.add("attack");
assert(!context.funWallMemoryMovementStarted(controller));
pressed.add("jump");
assert(context.funWallMemoryMovementStarted(controller));
pressed.clear(); assert(context.funWallMemoryMovementStarted(controller));
const anchor = { read_key: "21:memory_1", phase: "idle", glyph_count: 31 };
context.funWallMemoryStart(anchor);
assert.equal(anchor.revealed, 1); assert.equal(cues, 1); assert.equal(saves, 0);
context.funWallMemoryAdvance(anchor, 1.5, false, 1000);
assert.equal(anchor.phase, "typing"); assert.equal(saves, 0);
assert.equal(anchor.revealed, 16);
// A new attempt before completion has no persistent read flag.
assert(!context.funWallMemoryWasRead(anchor.read_key));
context.funWallMemoryAdvance(anchor, 1.5, false, 1000);
assert.equal(anchor.phase, "hold"); assert.equal(saves, 1);
assert(context.funWallMemoryWasRead(anchor.read_key));
context.funWallMemoryAdvance(anchor, 2.5, true, 80);
assert.equal(anchor.phase, "hold");
context.funWallMemoryAdvance(anchor, .01, true, 181);
assert.equal(anchor.phase, "fade");
context.funWallMemoryAdvance(anchor, .5, true, 80);
assert.equal(anchor.phase, "consumed");
context.funWallMemoryMarkRead(anchor.read_key); assert.equal(saves, 1);
context.funResetWallMemories(); assert(!context.funWallMemoryWasRead(anchor.read_key));
assert.equal(settings.defaults.activation_distance, 80);
// Validate the controller's death boundary and complete centred layout from actual GML.
const metadata = JSON.parse(fs.readFileSync(path.join(root, "RandomForest/datafiles/narrative/memory_font.json")));
Object.assign(context.global, { memory_alphabet: metadata.characters, memory_glyph_bounds: metadata.glyph_bounds,
  memory_glyph_height: metadata.glyph_height, memory_font: 1 });
Object.assign(context, {
  string: String, ord: character => character.codePointAt(0),
  string_width: text => Array.from(text).reduce((n,c)=>n+(metadata.advances[metadata.characters.indexOf(c)]||0),0),
  string_length: text => Array.from(text).length, string_split: (text,sep)=>text.split(sep),
  string_copy: (text,start,length)=>text.slice(start-1,start-1+length),
  string_delete: (text,start,length)=>text.slice(0,start-1)+text.slice(start-1+length),
  string_char_at: (text,index)=>text[index-1], string_pos: (needle,text)=>text.indexOf(needle)+1,
  array_length: array=>array.length, array_push: (array,item)=>array.push(item),
  floor: Math.floor, ceil: Math.ceil, draw_get_font: ()=>1, draw_set_font() {},
  make_colour_rgb: (r,g,b)=>(r<<16)+(g<<8)+b,
  point_distance: (x,y,tx,ty)=>Math.hypot(x-tx,y-ty),
  view_camera: [1], camera_get_view_x: ()=>0, camera_get_view_y: ()=>0,
  camera_get_view_width: ()=>480, camera_get_view_height: ()=>270,
  game_get_speed: ()=>60, gamespeed_fps: 1, player_states: {die:9},
  oPlayer: { x:200,y:140,health:0,state:9 },
  array_sort: (array,compare)=>array.sort(compare)
});
load("scriptWallMemorySelection"); load("scriptWallMemoryRender"); load("scriptWallMemoryFlow");
assert.equal(JSON.stringify(context.funWallMemoryWrap("abcdefghijk",32)),
  JSON.stringify(require('../../visualizer/wall-memories.js').WallMemoryModel.wrap(
    {measureText: text=>({width:context.string_width(text)})},"abcdefghijk",32)));
const prepared = {text:"Хватит.\nСтой.", width:120,x:200,y:130,read_key:"21:memory_2"};
context.funWallMemoryPrepareAnchor(prepared);
assert.deepEqual(Array.from(context.funWallMemoryPalette("evening")), settings.palette);
assert.deepEqual(Array.from(context.funWallMemoryPalette("morning")), settings.palette);
assert.deepEqual(Array.from(context.funWallMemoryPalette("night")), settings.palette_by_theme.night);
assert.equal(prepared.memory_left,140); assert.equal(prepared.memory_top,102);
assert.equal(prepared.line_x[0],Math.floor((120-context.string_width("Хватит."))/2+.5));
const dying = { ...prepared, phase:"typing", revealed:prepared.glyph_count-1,phase_elapsed:0, ready:true };
const control = {ready:true,movement_started:true,level_number:21,anchors:[dying]};
context.funWallMemoryUpdateController(control);
assert.equal(dying.phase,"typing"); assert(!context.funWallMemoryWasRead(dying.read_key));
context.oPlayer.health=2; context.oPlayer.state=0;
context.funWallMemoryUpdateController(control);
assert.equal(dying.phase,"typing");
for (let frame = 1; frame < 11; frame++) context.funWallMemoryUpdateController(control);
assert.equal(dying.phase,"hold"); assert(context.funWallMemoryWasRead(dying.read_key));
console.log("Actual GML: movement/cue, offscreen completion, read/reset, hold/fade, death boundary, wrapping and fixed centring passed.");

// Exercise the production cache and draw functions with observable GPU state.
let blend = [7, 8, 9, 10], filter = true, font = 42, colour = 123, alpha = .6;
let halign = 2, valign = 3, rebuilds = 0;
const surfaces = new Set(), surfaceDraws = [], cacheModes = [];
Object.assign(context, {
  c_black: 0, fa_left: 0, fa_top: 0, bm_src_alpha: 4, bm_inv_src_alpha: 5, bm_one: 1,
  surface_exists: id => surfaces.has(id),
  surface_create: () => { surfaces.add(12); return 12; },
  surface_set_target() { rebuilds++; cacheModes.push([...blend]); }, surface_reset_target() {},
  draw_clear_alpha() {}, draw_text() {},
  draw_get_font: () => font, draw_set_font: value => { font = value; },
  draw_get_colour: () => colour, draw_set_colour: value => { colour = value; },
  draw_get_alpha: () => alpha, draw_set_alpha: value => { alpha = value; },
  draw_get_halign: () => halign, draw_set_halign: value => { halign = value; },
  draw_get_valign: () => valign, draw_set_valign: value => { valign = value; },
  gpu_get_blendmode_ext_sepalpha: () => [...blend],
  gpu_set_blendmode_ext_sepalpha: (...values) => { blend = values.length === 1 ? [...values[0]] : values; },
  gpu_set_blendmode_ext: (source, destination) => { blend = [source,destination,source,destination]; },
  gpu_get_texfilter: () => filter, gpu_set_tex_filter: value => { filter = value; },
  draw_surface_part_ext: (...args) => surfaceDraws.push({ args, blend: [...blend], filter })
});
const rendered = {...prepared, ready:true, phase:"hold", phase_elapsed:0,
  role:"regular", text_surface:-1, cached_revealed:-1, revealed:4};
context.funWallMemoryDraw(rendered);
assert.deepEqual(cacheModes[0], [4,5,1,5]);
assert.equal(rebuilds, 1);
assert.deepEqual(blend, [7,8,9,10]); assert.equal(filter, true);
assert.deepEqual([font,colour,alpha,halign,valign], [42,123,.6,2,3]);
assert.deepEqual(surfaceDraws[0].blend, [1,5,1,5]);
assert.equal(surfaceDraws[0].filter, false);
assert.equal(surfaceDraws[0].args.at(-1), .9);
assert.equal(surfaceDraws[0].args.at(-2), context.make_colour_rgb(230,230,230));
rendered.phase = "fade"; rendered.phase_elapsed = settings.defaults.fade_seconds / 2;
context.funWallMemoryDraw(rendered);
assert.equal(rebuilds, 1); // Fade reuses cached pixels.
assert.equal(surfaceDraws.at(-1).args.at(-1), .45);
assert.equal(surfaceDraws.at(-1).args.at(-2), context.make_colour_rgb(115,115,115));
const drawsBeforeClip = surfaceDraws.length;
context.funWallMemoryDrawClipped(rendered, .45, [0,0,10,10]);
assert.equal(surfaceDraws.length, drawsBeforeClip);
assert.deepEqual(blend, [7,8,9,10]); assert.equal(filter, true);
console.log("Actual GML: premultiplied cache/draw, fade RGB/alpha, cache reuse, clipping and complete GPU/draw state restoration passed.");
