/** Exercise speaker/body colours, parallax sampling and plant-flash draw state from actual GML. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
const read = file => fs.readFileSync(path.join(root, file), "utf8");
const rgb = (r,g,b) => r | g << 8 | b << 16;
let shader = -1, draws = [], layers = {}, camera = {x:372,y:207};
const c = vm.createContext({
  self:{}, global:{dialogue_font_12:12}, c_white:rgb(255,255,255), c_ltgray:rgb(192,192,192),
  ORANGE_FIREFLY_COLOUR:rgb(255,100,0), shRootMawHitFlash:42,
  sRootMawHurt:"sRootMawHurt", sRootMawRosette:"sRootMawRosette", sBarkBomberAttack:"barrelAttack",
  gamespeed_fps:0, floor:Math.floor, min:Math.min, max:Math.max, abs:Math.abs,
  clamp:(v,a,b)=>Math.max(a,Math.min(b,v)), string_length:s=>s.length,
  string_copy:(s,i,n)=>s.slice(i-1,i-1+n), string_char_at:(s,i)=>s[i-1],
  string_width:()=>5, string_replace_all:(s,a,b)=>s.replaceAll(a,b), string:String,
  array_push:(a,v)=>a.push(v), array_length:a=>a.length,
  variable_struct_exists:(s,k)=>Object.hasOwn(s,k), make_colour_rgb:rgb,
  draw_set_font(){}, funLayoutDialogue:letters=>[{glyphs:letters}],
  sprite_get_speed:()=>1000/83, game_get_speed:()=>60,
  sprite_get_name:s=>s, asset_get_index:s=>s, funThemeSprite:s=>s,
  funForestEnemyPose:()=>({x:0,y:0}), shader_is_compiled:()=>true,
  shader_current:()=>shader, shader_set:s=>{shader=s;}, shader_reset:()=>{shader=-1;},
  draw_sprite_ext:(...args)=>draws.push({shader,args}),
  view_camera:[0], camera_get_view_x:()=>camera.x, camera_get_view_y:()=>camera.y,
  layer_x:(id,x)=>{(layers[id]??={}).x=x;}, layer_y:(id,y)=>{(layers[id]??={}).y=y;},
  layer_background_alpha:(id,alpha)=>{(layers[id]??={}).alpha=alpha;},
  instance_exists:()=>true, oAmbientSystem:{weather:{rain:.3}}
});

/** Translate GML operators without replacing production calculations. */
function translate(source) {
  return source.replace(/\band\b/g,"&&").replace(/\bor\b/g,"||").replace(/\bmod\b/g,"%");
}
/** Load a production script into the test context. */
function load(name) { vm.runInContext(translate(read(`scripts/${name}/${name}.gml`)),c); }
load("scriptDialogueText"); load("scriptDialoguePlayback"); load("scriptForestEnemyCore");
for (const speaker of ["Система","Голос"]) {
  c.self={lines:[{speaker,text:"До [orange]акцент[/orange] после"}],line_index:0,progress:{},text_width:424,line_height:18,rows_per_page:4};
  c.funPrepareDialogueLine();
  assert.equal(c.self.speaker_colour,speaker==="Система"?rgb(139,186,218):c.c_white);
  const glyphs=c.self.pages[0].glyphs;
  assert.equal(glyphs[0].colour,c.c_ltgray);
  assert.equal(glyphs[3].colour,c.ORANGE_FIREFLY_COLOUR);
  assert.equal(glyphs.at(-1).colour,c.c_ltgray);
}

// The original Hurt frame 1 occupies ticks 5..9 at 60 FPS.
const elapsed=[];
c.self={forest_kind:"maw",is_dead:false};
for(let tick=0;tick<=24;++tick) {
  c.self.hurt_countdown_counter=24-tick;
  if(c.funForestMawHitFlashActive()) elapsed.push(tick);
}
assert.deepEqual(elapsed,[5,6,7,8,9]);
for(const fatal of [false,true]) for(const previous of [-1,7]) {
  c.self={forest_kind:"maw",is_dead:fatal,hurt_countdown_counter:18,sprite_index:"sRootMawAttack",
    image_index:3,x:300,y:396,image_xscale:-1,image_yscale:1,image_alpha:1,ambient_clock:0};
  shader=previous; draws=[]; c.funForestEnemyDraw();
  assert.equal(shader,previous,"restore the prior shader after both plant parts");
  assert.deepEqual(draws.map(d=>d.shader),Array(2).fill(fatal?previous:42));
  assert.equal(draws[0].args[0],"sRootMawAttackBare");
  assert.equal(draws[0].args[1],3);
  assert.equal(draws[1].args[0],"sRootMawRosette");
  assert(draws.every(d=>d.args.at(-1)===1),"damage never fades the plant");
  assert.equal(c.self.sprite_index,"sRootMawAttack");
}

// Snap background displacement, preserving the fractional camera and exact rain registration.
const parallax=translate(read("objects/oParallax/Draw_72.gml"));
for(const position of [{x:372,y:207},{x:372.25,y:203.75},{x:12,y:12},{x:0,y:0}]) {
  camera={...position}; layers={};
  c.self={background_to_view_ratio_x:.625,background_to_view_ratio_y:153/234,
    layer_id:1,rain_layer_id:2,rain_background_id:3};
  vm.runInContext(`(function(){${parallax}})()`,c);
  assert.equal(c.self.x-camera.x,Math.floor(camera.x*(.625-1)+.5));
  assert.equal(c.self.y-camera.y,Math.floor(camera.y*(153/234-1)+.5));
  assert.deepEqual(layers[1],layers[2]); assert.equal(layers[3].alpha,.6);
  assert.deepEqual(camera,position,"camera remains unrounded");
}
console.log("PASS: blue speaker label only, body/emphasis colours, white-flash timing/pose/opacity/shader restoration, integer screen parallax and registered rain");
