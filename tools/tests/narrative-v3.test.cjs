/** Exercise real v3 timing, finale sequencing and cosmetic memory effects. */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../../RandomForest');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const translate = source => source.replace(/^#macro (\w+) (.+)$/gm, 'const $1 = $2;').replace(/\band\b/g, '&&').replace(/\bor\b/g, '||').replace(/\bmod\b/g, '%');
let finished = 0, destroyed = 0, resumed = 0;
const c = vm.createContext({
  self: {}, global: {dialogue_font_12: 12, key_pause: 'escape'},
  c_white: 0xffffff, c_ltgray: 0xcccccc, ORANGE_FIREFLY_COLOUR: 123,
  make_colour_rgb: (r,g,b) => r | g << 8 | b << 16,
  array_length: a => a.length, array_push: (a,v) => a.push(v),
  array_delete: (a,i,n) => a.splice(i,n),
  string_length: s => s.length, string_char_at: (s,i) => s[i-1],
  string_copy: (s,i,n) => s.slice(i-1,i-1+n), string_width: () => 1,
  string_replace_all: (s,a,b) => s.replaceAll(a,b), string: String,
  variable_struct_exists: (s,k) => Object.hasOwn(s,k), draw_set_font() {},
  round: Math.round, power: Math.pow, min: Math.min, max: Math.max, lerp: (a,b,t) => a+(b-a)*t,
  lengthdir_x: (l,a) => l*Math.cos(a*Math.PI/180), lengthdir_y: (l,a) => -l*Math.sin(a*Math.PI/180),
  point_distance: (x,y,xx,yy) => Math.hypot(x-xx,y-yy),
  oPlayer: {visible:true,state:0,bbox_left:90,bbox_right:100,bbox_top:100,bbox_bottom:120},
  oPauseMenu: {paused:false}, oFadeIn: -1, oPlayerTapSword: -2, vk_space:'space',
  player_states: {idle:0,move:1,die:2}, keyboard_check_pressed: () => false,
  instance_exists: obj => obj === c.oPlayer,
  instance_find: () => c.oPlayer,
  instance_destroy: () => {destroyed++;},
});
/** Load production code, translating only GML operator spelling. */
function load(name) { vm.runInContext(translate(read(`scripts/${name}/${name}.gml`)), c); }
for (const name of ['scriptDialogueText','scriptDialogueLayout','scriptDialoguePlayback','scriptStoryEnding','scriptMemoryAbsorption']) load(name);
/** Prepare one production conversation with narrow pages when requested. */
function begin(text, auto=false, width=424, rows=4) {
  c.self={text_width:width,line_height:18,rows_per_page:rows};
  c.funBeginDialogue([{text,auto_finish:auto}], {},30,()=>{finished++;});
}
/** Wait for the actual typing clock rather than forcing a reveal. */
function finishTyping() {
  const count = c.self.pages[c.self.page_index].glyphs.length;
  while (c.self.revealed < count) c.funStepDialogueTyping();
}
// Space never changes partial text or its timing.
begin('A...');
c.funStepDialogueTyping();
c.funAdvanceDialogue();
assert.equal(c.self.revealed, 0);
assert.equal(c.self.typing_frames, 1, 'ignored Space preserves the current delay');
c.funStepDialogueTyping();
c.funAdvanceDialogue();
assert.equal(c.self.revealed, 1, 'ellipsis cannot be skipped');
finishTyping();
c.funAdvanceDialogue();
assert.equal(finished, 1, 'Space advances once typing is complete');
finished = 0;
const dotFrames = vm.runInContext('60 * DIALOGUE_ELLIPSIS_DELAY_SECONDS', c);
for (const n of [1,2,3,4,8]) {
  begin('.'.repeat(n));
  const frames=n>=3?dotFrames:2;
  for (let dot=0;dot<n;dot++) {
    for(let t=1;t<frames;t++) c.funStepDialogueTyping();
    assert.equal(c.self.revealed,dot);
    c.funStepDialogueTyping(); assert.equal(c.self.revealed,dot+1);
  }
}
begin('A...B');
c.funStepDialogueTyping(); c.funStepDialogueTyping();
assert.equal(c.self.revealed,1);
for(let i=0;i<dotFrames-1;i++) c.funStepDialogueTyping();
assert.equal(c.self.revealed,1);
c.funStepDialogueTyping(); assert.equal(c.self.revealed,2);
c.funAdvanceDialogue(); assert.equal(c.self.revealed,2,'Space leaves partial text unchanged');
assert.equal(finished,0,'Partial text cannot advance');
finishTyping();
c.funAdvanceDialogue(); assert.equal(finished,1);

begin('........',false,2,1);
assert.equal(c.self.pages.length,4);
assert(c.self.pages.every(p=>p.glyphs.every(g=>g.delay_frames===dotFrames)));
c.funAdvanceDialogue(); assert.equal(c.self.page_index,0);
finishTyping(); c.funAdvanceDialogue();
assert.equal(c.self.page_index,1); assert.equal(c.self.typing_frames,0);
for(let i=0;i<dotFrames-1;i++) c.funStepDialogueTyping();
assert.equal(c.self.revealed,0,'new page preserves first dot delay');

begin('Удаление........ Успешно.',true);
finishTyping(); c.funAdvanceDialogue();
assert.equal(finished,1,'automatic ending cannot finish before Draw');
const step = translate(read('objects/oDialogue/Step_0.gml')).replace(/\bexit\b/g,'return');
vm.runInContext(`(function(){${step}})()`,c);
assert.equal(finished,1);
const draw = read('objects/oDialogue/Draw_64.gml').split('// Signal completion')[1];
c.page = c.self.pages[c.self.page_index];
c.line = c.self.lines[c.self.line_index];
vm.runInContext(translate('// Signal completion'+draw),c);
assert.equal(c.self.complete_drawn,true);
vm.runInContext(`(function(){${step}})()`,c);
assert.equal(finished,2,'one rendered full page permits immediate next-step exit');

const ending=JSON.parse(read('datafiles/narrative/dialogues/ck_after_41.json')).lines;
assert.deepEqual(ending.filter(l=>l.action).map(l=>l.action),['first_walk','freedom','portal_run']);
assert(ending.filter(l=>l.speaker==='Она').length >= 2);
assert.equal(ending.at(-1).auto_finish,true);
// Drive the real locked tail with both Escape and Space pressed throughout.
const tail = ending.slice(ending.findIndex(l => l.lock_input));
c.self = {text_width:424,line_height:18,rows_per_page:4};
c.funBeginDialogue(tail, {}, 30, () => {finished++;});
finishTyping();
c.funAdvanceDialogue();
assert.equal(c.self.line_index,0,'Space on the completion frame cannot skip deletion lock');
/** Present the actual completion hook, as the GUI does after drawing. */
function presentPage() {
  c.page=c.self.pages[c.self.page_index]; c.line=c.self.lines[c.self.line_index];
  vm.runInContext(translate('// Signal completion'+draw),c);
}
presentPage();
assert.equal(c.self.input_locked,true);
c.keyboard_check_pressed=()=>true;
for(let i=0;i<299;i++) vm.runInContext(`(function(){${step}})()`,c);
assert.equal(c.self.line_index,0);
assert.equal(c.self.auto_frames,299);
vm.runInContext(`(function(){${step}})()`,c);
assert.equal(c.self.line_index,1,'controller message holds for exactly five seconds');
for(let i=0;i<10;i++) vm.runInContext(`(function(){${step}})()`,c);
assert.equal(c.self.auto_frames,0,'hold starts after typing and presentation');
finishTyping(); presentPage();
for(let i=0;i<29;i++) vm.runInContext(`(function(){${step}})()`,c);
assert.equal(c.self.line_index,1);
vm.runInContext(`(function(){${step}})()`,c);
assert.equal(c.self.line_index,2,'settings message holds for half a second');
finishTyping(); presentPage();
const beforeAutoFinish=finished;
vm.runInContext(`(function(){${step}})()`,c);
assert.equal(finished,beforeAutoFinish+1,'Escape cannot stall automatic ending');
c.keyboard_check_pressed=()=>false;

c.self={ending_action:'freedom',ending_frame:269,portal_ready:false,show_dialogue:()=>{resumed++;}};
c.oPlayer.is_on_ground=true;
c.funStoryEndingStep();
assert.equal(resumed,1); assert.equal(c.self.ending_action,'');
assert.equal(c.self.portal_ready,false,'freedom must return to speech, not open portal');

c.self={memory_particles:[]};
c.funMemoryAbsorptionBurst(0,0); assert.equal(c.self.memory_particles.length,48);
for(let i=0;i<12;i++) c.funMemoryAbsorptionStep();
assert(c.self.memory_particles.every(p=>p.x>0));
c.oPlayer.bbox_left=290; c.oPlayer.bbox_right=300;
const before=c.self.memory_particles[0].x;
c.funMemoryAbsorptionStep(); assert(c.self.memory_particles[0].x>before,'particles follow a teleport');
c.oPlayer.state=c.player_states.die;
for(let i=0;i<13;i++) c.funMemoryAbsorptionStep();
assert.equal(c.self.memory_particles.length,0,'particles expire when player dies');
console.log('PASS: exact ellipsis delays, pagination, unskippable typing, rendered auto-ending, separate portal beat and memory absorption lifecycle');

// Execute menu rendering at two window sizes, including overflow and state restoration.
let nativeWidth=1440, nativeHeight=810, filter=false, matrix='original', font=12, colour=7, alpha=.7, ha=1, va=2;
let calls=[];
Object.assign(c, {
  matrix_world:0, fa_left:0, fa_top:0, ceil:Math.ceil,
  display_get_gui_width:()=>480, display_get_gui_height:()=>270,
  application_get_position:()=>[0,0,nativeWidth,nativeHeight],
  matrix_get:()=>matrix, matrix_set:(kind,value)=>{matrix=value;},
  matrix_build:(...args)=>args, draw_get_font:()=>font, draw_set_font:v=>{font=v;},
  draw_get_color:()=>colour, draw_set_color:v=>{colour=v;},
  draw_get_alpha:()=>alpha, draw_set_alpha:v=>{alpha=v;},
  draw_get_halign:()=>ha, draw_set_halign:v=>{ha=v;},
  draw_get_valign:()=>va, draw_set_valign:v=>{va=v;},
  gpu_get_texfilter:()=>filter, gpu_set_tex_filter:v=>{filter=v;},
  string_width:s=>s.length*11, string_height_ext:(s,sep,w)=>Math.ceil(s.length*11/w)*22,
  draw_text_ext:(x,y,text,sep,w)=>calls.push({x,y,text,w,matrix}),
});
load('scriptBrokenMenu');
for (const size of [[1440,810],[640,360]]) {
  [nativeWidth,nativeHeight]=size;
  c.self={runtime_errors:100,runtime_error_font:99}; calls=[];
  c.funBrokenMenuErrors();
  assert(calls.length>0 && calls.length<100);
  assert(calls.every(d=>d.x>=16 && d.x+d.w<=nativeWidth-16));
  assert.equal(calls[0].matrix[6],480/nativeWidth);
  assert.equal(calls[0].matrix[7],270/nativeHeight);
  assert.equal(matrix,'original'); assert.equal(filter,false); assert.equal(font,12);
  assert.equal(colour,7); assert.equal(alpha,.7); assert.equal(ha,1); assert.equal(va,2);
  const last=calls.at(-1);
  assert(last.y+c.string_height_ext(last.text,-1,last.w)>0,'oldest retained message is still visible');
}
console.log('PASS: native menu coordinates, bounded overflow and complete render-state restoration');
