const assert=require('assert');
const {WallMemoryModel:M,createWallMemoryEditor}=require('../wall-memories.js');
const config={defaults:{line_height:24,opacity:1},palette:[[1,2,3]],special:{highlight_word:'осталось',highlight_colour:[4,5,6]}};
assert.deepEqual(M.bounds({x:100,y:20,width:168}),{left:16,top:2,width:168,height:36});
assert.deepEqual(M.point({clientX:35,clientY:45},{left:10,top:20,width:100,height:100},200,200),{x:50,y:50});
assert(M.eligible({min_collected:2},11,2,false));
assert(!M.eligible({min_collected:2},11,1,false));
assert(!M.eligible({requires_all_previous:true},11,10,true));
assert(M.eligible({requires_all_previous:true},11,10,false));
assert(!M.eligible({role:'missing_previous'},11,10,false));
assert(M.eligible({role:'missing_previous'},11,9,true));
assert.equal(M.hash(21,'memory_1'),M.hash(21,'memory_1'));
assert.notEqual(M.hash(21,'memory_1'),M.hash(21,'memory_2'));
assert.deepEqual(M.wrap({measureText:s=>({width:s.length*8})},'abc def\nxy',30),['abc','def','xy']);
assert.deepEqual(M.wrap({measureText:s=>({width:s.length*8})},'abcdef',24),['abc','def']);
const controls={};for(const name of ['width','role','text','min_collected','delete','position','preview','boxes','missing','collected','count','message'])controls[name]={dataset:{memory:name},value:'',checked:false,handlers:{},addEventListener(type,fn){this.handlers[type]=fn},setAttribute(){},removeAttribute(){},replaceChildren(){},appendChild(){}};
controls.preview.checked=controls.boxes.checked=true;controls.collected.value='0';
const panel={querySelectorAll:()=>Object.values(controls),classList:{toggle(){}}};
global.document={getElementById:()=>panel,fonts:{load:()=>Promise.resolve()},createElement:()=>({})};global.fetch=async()=>({ok:true,json:async()=>config});
global.Image=class { set src(value) { this.onload(); } };
const ctx={save(){},restore(){},measureText:s=>({width:s.length*8}),fillText(){},fillRect(){},strokeRect(){},setLineDash(){}};
const canvas={getBoundingClientRect:()=>({left:0,top:0,width:120,height:120}),getContext:()=>ctx,focus(){},setPointerCapture(){}};
const state={level:{width:10,height:10,map:Array(10).fill('..........')},loadedPath:'test',levelNumber:1,undoStack:[],editRevision:0};let saves=0,renders=0;
const editor=createWallMemoryEditor({state,canvas,render:()=>renders++,save:()=>saves++,hideTooltip(){}});
const evt=(x,y)=>({button:0,pointerId:1,clientX:x,clientY:y,preventDefault(){}});
assert.equal(editor.pointerDown(evt(32,48)),false);assert.equal(state.level.wall_memories,undefined);
editor.setActive(true);assert.equal(editor.pointerDown(evt(32,48)),true);assert.equal(editor.isDragging(),true);assert.equal(saves,0);editor.pointerUp();assert.equal(saves,1);assert.equal(state.level.wall_memories[0].x,32);assert.equal(state.level.wall_memories[0].y,48);assert.equal(state.level.wall_memories[0].width,168);assert.equal(state.level.wall_memories[0].id,'memory_1');
assert.equal(editor.pointerDown(evt(32,48)),true);editor.pointerMove(evt(42,58));editor.pointerUp();assert.equal(saves,2);assert.equal(state.level.wall_memories[0].x,42);assert.equal(state.level.wall_memories[0].y,58);
controls.width.value='200';controls.width.handlers.change();assert.equal(state.level.wall_memories[0].width,200);assert.equal(saves,3);
const map=JSON.stringify(state.level.map);controls.delete.handlers.click();assert.equal(state.level.wall_memories.length,0);assert.equal(saves,4);editor.undo(state.undoStack.pop());assert.equal(state.level.wall_memories.length,1);assert.equal(JSON.stringify(state.level.map),map);
while(state.undoStack.length)editor.undo(state.undoStack.pop());assert.equal('wall_memories' in state.level,false);assert.equal(JSON.stringify(state.level.map),map);
console.log('Wall editor geometry, inline conditions, mode gating, drag, save and exact legacy undo assertions passed.');

// Checks the loaded sprite atlas rather than browser font measurements.
async function checkAtlasPreview() {
  const path = require('path');
  const read = name => JSON.parse(require('fs').readFileSync(
    path.join(__dirname, '../../RandomForest/datafiles/narrative', name), 'utf8'));
  const metadata = read('memory_font.json');
  global.fetch = async url => ({ ok: true, json: async () =>
    url.endsWith('memory_font.json') ? metadata : read('wall_memories.json') });
  global.Image = class {
    // Completes the local atlas load without needing a browser canvas backend.
    set src(value) {
      assert(value.endsWith('fonts/memory-alphabet.png'));
      this.width = 352; this.height = 286; this.onload();
    }
  };
  document.createElement = type => type === 'canvas'
    ? { getContext: () => ({ drawImage() {}, fillRect() {} }) } : { setAttribute() {}, addEventListener() {} };
  const drawn = [], boxes = [];
  ctx.drawImage = (...args) => drawn.push({ args, alpha: ctx.globalAlpha });
  ctx.strokeRect = (...args) => boxes.push(args);
  state.level.wall_memories = [{ id: 'test_right', x: 220, y: 100,
    width: 168, role: 'regular', text: 'Кто я?', min_collected: 0 }];
  const preview = createWallMemoryEditor({ state, canvas, render() {}, save() {}, hideTooltip() {} });
  await new Promise(resolve => setImmediate(resolve));
  preview.setActive(true);
  preview.pointerDown(evt(220, 100)); preview.pointerUp();
  preview.draw(ctx);
  assert.deepEqual(boxes.at(-1), [136.5, 84.5, 168, 32]);
  const ink = drawn.filter(call => call.alpha === .9);
  assert.equal(ink.length, 5); // The space advances without drawing its hidden marker.
  const fullWidth=Array.from('Кто я?').reduce((n,c)=>n+metadata.advances[metadata.characters.indexOf(c)],0);
  const start=136+Math.round((168-fullWidth)/2);
  assert.equal(ink[0].args[5], start);
  assert.equal(ink[1].args[5], start + metadata.advances[metadata.characters.indexOf('К')]);
  assert.equal(ctx.imageSmoothingEnabled, false);
  console.log('Sprite-atlas loading, centred alignment, baseline, spacing and hidden-space preview checks passed.');
}
checkAtlasPreview().catch(error => { console.error(error); process.exitCode = 1; });
