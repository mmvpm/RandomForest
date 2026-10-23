"use strict";

// Edits resident moth colonies without changing terrain, gameplay entities or other metadata.
function createMothNestEditor({ state, canvas, render, save, hideTooltip }) {
  const panel = document.getElementById("moth-nest-panel");
  const control = name => document.getElementById(`moth-${name}`);
  let active = false, selected = null, drag = null, placing = false;

  // Reads the optional collection without introducing it into untouched maps.
  function nests() { return state.level?.moth_nests || []; }
  // Finds the selected colony by its persistent ID.
  function item() { return nests().find(nest => nest.id === selected); }
  // Preserves the exact absence or value for shared undo and persistence.
  function snapshot() { return {kind:"moth_nests",value:state.level.moth_nests === undefined ? undefined : structuredClone(state.level.moth_nests)}; }
  // Commits one completed gesture through the original save queue.
  function commit(before) {
    if (JSON.stringify(before.value) === JSON.stringify(state.level.moth_nests)) return;
    state.undoStack.push(before); state.editRevision++; refresh(); render(); save();
  }
  // Converts CSS-scaled input to whole native world pixels.
  function point(event) {
    const bounds = canvas.getBoundingClientRect();
    return {x:Math.round((event.clientX-bounds.left)/bounds.width*state.level.width*12),
      y:Math.round((event.clientY-bounds.top)/bounds.height*state.level.height*12)};
  }
  // Rejects points in visible stone, including collision-free black mass X.
  function clear(position) {
    const x = Math.floor(position.x / 12), y = Math.floor(position.y / 12);
    return x >= 0 && y >= 0 && x < state.level.width && y < state.level.height &&
      !"#X=^v<>UDLR".includes(state.level.map[y][x]);
  }
  // Shows authoring controls, count and explicit keyboard help.
  function refresh(reset = false) {
    if (reset) { selected = null; drag = null; }
    const nest = item();
    control("status").textContent = `${nests().length} / 3 колоний · ${placing ? "щёлкните по воздуху" : "выберите или переместите точку"}`;
    control("count").disabled = control("radius").disabled = !nest;
    control("delete").disabled = !nest;
    control("add").disabled = nests().length >= 3;
    control("count").value = nest?.count ?? 30;
    control("radius").value = nest?.radius ?? 65;
    control("position").textContent = nest ? `${nest.id} · ${nest.x}, ${nest.y} px` : "На карте без точек мотыльков нет. Геометрия и расстановка врагов не меняются.";
  }
  // Draws actual colony extent and an unmistakable authoring marker in native coordinates.
  function draw(context) {
    if (!state.level) return;
    for (const nest of nests()) {
      const radius = nest.radius ?? 65;
      context.save();
      context.strokeStyle = selected === nest.id && active ? "#eff8c5" : "#b1c7ca";
      context.fillStyle = "rgba(170,202,196,.08)";
      context.beginPath(); context.ellipse(nest.x,nest.y,radius,radius*45/130,0,0,Math.PI*2); context.fill(); context.stroke();
      context.lineWidth = 1;
      for (let i=0;i<5;i++) {
        const angle=i*2.4;
        const x=nest.x+Math.cos(angle)*radius*.6, y=nest.y+Math.sin(angle)*radius*.35;
        context.beginPath();context.moveTo(x-3,y-1);context.lineTo(x,y+1);context.lineTo(x+3,y-1);context.stroke();
      }
      if (active) { context.fillStyle="#d8e5d9";context.font="8px sans-serif";context.fillText(nest.id,nest.x+4,nest.y-radius*45/130-4); }
      context.restore();
    }
  }
  // Creates or grabs a resident colony; an empty edit mode never paints terrain underneath.
  function pointerDown(event) {
    if (!active) return false;
    if (!state.level || event.button !== 0) return true;
    canvas.focus({preventScroll:true});
    const position = point(event);
    const hit = [...nests()].reverse().find(nest => Math.hypot(nest.x-position.x,nest.y-position.y) <= (nest.radius ?? 65));
    if (placing && nests().length < 3 && clear(position)) {
      const before=snapshot();let number=1;
      while(nests().some(nest=>nest.id===`moths_${number}`)) number++;
      const nest={id:`moths_${number}`,x:position.x,y:position.y,count:30,radius:65};
      state.level.moth_nests=[...nests(),nest];selected=nest.id;placing=false;commit(before);
    } else if (hit) {
      selected=hit.id;drag={before:snapshot(),dx:position.x-hit.x,dy:position.y-hit.y};
      canvas.setPointerCapture(event.pointerId);
    } else selected=null;
    hideTooltip();refresh();render();event.preventDefault();return true;
  }
  // Moves only the metadata anchor while respecting visual terrain occupancy.
  function pointerMove(event) {
    if (!active) return false;
    if (!drag || !item()) return true;
    const position=point(event);
    position.x-=drag.dx;position.y-=drag.dy;
    if (clear(position)) {item().x=position.x;item().y=position.y;render();refresh();}
    return true;
  }
  // Makes dragging one undoable operation and one ordered save.
  function pointerUp() {
    if (!active) return false;
    if (drag) {const before=drag.before;drag=null;commit(before);}
    return true;
  }
  // Deletes only the selected authored colony.
  function remove() {
    if (!item()) return;
    const before=snapshot();state.level.moth_nests=nests().filter(nest=>nest.id!==selected);
    selected=null;commit(before);
  }
  // Edits one bounded visual parameter without changing the map.
  function change(name,min,max) {
    if (!item()) return;
    const before=snapshot();item()[name]=Math.max(min,Math.min(max,Math.round(Number(control(name).value)||min)));commit(before);
  }
  // Restores the original optional metadata field exactly.
  function undo(edit) {
    if (edit.kind!=="moth_nests") return false;
    if(edit.value===undefined) delete state.level.moth_nests;
    else state.level.moth_nests=structuredClone(edit.value);
    selected=null;state.editRevision++;refresh();render();save();return true;
  }
  // Keeps editor selection and keyboard handling separate from normal level navigation.
  function setActive(value) {pointerUp();active=value;placing=false;hideTooltip();refresh();render();}
  // Handles deletion and cancellation only inside this editing mode.
  function keyboard(event) {
    if(!active) return false;
    if(event.key==="Delete"||event.key==="Backspace") remove();
    else if(event.key==="Escape") {placing=false;refresh();}
    else return false;
    event.preventDefault();return true;
  }
  control("add").addEventListener("click",()=>{placing=true;refresh();});
  control("delete").addEventListener("click",remove);
  control("count").addEventListener("change",()=>change("count",18,36));
  control("radius").addEventListener("change",()=>change("radius",36,80));
  refresh();
  return {draw,refresh,setActive,pointerDown,pointerMove,pointerUp,keyboard,undo,isEditing:()=>Boolean(drag),isActive:()=>active};
}

if (typeof module !== "undefined") module.exports = {createMothNestEditor};
