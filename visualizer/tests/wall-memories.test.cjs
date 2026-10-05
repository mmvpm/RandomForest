const assert=require('assert');
const {WallMemoryModel:M,createWallMemoryEditor}=require('../wall-memories.js');
const config={defaults:{font_size:18,line_height:20,opacity:.9},styles:{day:[1,2,3]},special:{text:'Там позади осталось'},phrases:[{id:'a',text:'один',from_level:11,to_level:12,min_collected:0},{id:'b',text:'два',from_level:11,to_level:12,min_collected:2},{id:'c',text:'все',from_level:11,to_level:12,min_collected:0,requires_all_previous:true}]};
assert.deepEqual(M.bounds({x:100,y:20,width:168,align:'right'}),{left:-68,top:20,width:168,height:60});
assert.deepEqual(M.point({clientX:35,clientY:45},{left:10,top:20,width:100,height:100},200,200),{x:50,y:50});
assert.equal(M.eligible(config,11,0).length,1);assert.equal(M.eligible(config,10,40).length,0);
assert.equal(M.assign(config,[{id:'x',role:'regular',text_id:'b'}],11,0,false).get('x'),undefined);
const anchors=[{id:'z',role:'regular',text_id:''},{id:'a',role:'regular',text_id:''}];
const selected=M.assign(config,anchors,11,2,false);assert.equal(new Set([...selected.values()].map(v=>v.id)).size,2);assert.deepEqual([...selected], [...M.assign(config,[...anchors].reverse(),11,2,false)]);
assert.deepEqual(M.wrap({measureText:s=>({width:s.length*8})},'abc def\nxy',30),['abc','def','xy']);
const controls={};for(const name of ['align','width','role','text_id','delete','position','preview','boxes','missing','collected','count','sample','message','text_ids'])controls[name]={dataset:{memory:name},value:'',checked:false,handlers:{},addEventListener(type,fn){this.handlers[type]=fn},setAttribute(){},removeAttribute(){},replaceChildren(){},appendChild(){}};
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
console.log('Wall editor geometry, phrase assignment, mode gating, drag, save and exact legacy undo assertions passed.');

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
    width: 168, align: 'right', role: 'regular', text_id: '' }];
  const preview = createWallMemoryEditor({ state, canvas, render() {}, save() {}, hideTooltip() {} });
  await new Promise(resolve => setImmediate(resolve));
  preview.setActive(true);
  preview.pointerDown(evt(60, 110)); preview.pointerUp();
  controls.sample.value = 'Кто я?'; controls.sample.handlers.input();
  preview.draw(ctx);
  assert.deepEqual(boxes.at(-1), [52.5, 100.5, 168, 32]);
  const ink = drawn.filter(call => call.alpha === 0.9);
  assert.equal(ink.length, 5); // The space advances without drawing its hidden marker.
  assert.equal(ink[0].args[5], 55);
  assert.equal(ink[1].args[5], 55 + metadata.advances[metadata.characters.indexOf('К')]);
  assert.equal(ctx.imageSmoothingEnabled, false);
  console.log('Sprite-atlas loading, right alignment, baseline, spacing and hidden-space preview checks passed.');
}
checkAtlasPreview().catch(error => { console.error(error); process.exitCode = 1; });
