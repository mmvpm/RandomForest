"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.join(__dirname, "../..");
const html = fs.readFileSync(path.join(root, "visualizer/index.html"), "utf8");

// Supplies only the DOM operations used by the actual editor scripts.
class Element {
  constructor() {
    this.handlers = {}; this.style = {}; this.dataset = {}; this.children = [];
    this.attributes = {}; this.hidden = false; this.value = ""; this.checked = false;
    this.clientWidth = 800; this.clientHeight = 600;
    this.classList = { toggle() {}, add() {}, remove() {} };
  }
  // Records UI event handlers for direct user-action simulation.
  addEventListener(name, handler) { this.handlers[name] = handler; }
  // Updates accessible state on the shared mode switch.
  setAttribute(name, value) { this.attributes[name] = value; }
  // Removes stale combobox keyboard selection metadata.
  removeAttribute(name) { delete this.attributes[name]; }
  // Replaces dynamically generated palette entries.
  replaceChildren(...children) { this.children = children; }
  // Adds a palette or phrase option.
  appendChild(child) { this.children.push(child); }
  // Adds optional multiple children to a container.
  append(...children) { this.children.push(...children); }
  // Returns a canvas context with no GPU dependency.
  getContext() { return context; }
  // Provides CSS-scaled pointer geometry used by the real anchor editor.
  getBoundingClientRect() { return { left: 0, top: 0, width: 120, height: 120 }; }
  // Moves keyboard focus to the canvas before dragging.
  focus() { document.activeElement = this; }
  // Represents browser pointer capture during a gesture.
  setPointerCapture() {}
  // Handles zoom centering without a real scrolling viewport.
  scrollTo() {}
  // Reports whether keyboard input belongs to a form field.
  matches() { return false; }
}

let renderTrace = null;
const canvasStates = [];
const context = new Proxy({ globalAlpha: 1,
  // Tracks nested alpha state so assertions exercise the actual canvas drawing path.
  save() { canvasStates.push(this.globalAlpha); },
  // Restores alpha after each sprite and overlay, as the browser canvas does.
  restore() { this.globalAlpha = canvasStates.pop() ?? 1; },
  // Records only source images and alpha, without a GPU or platform font dependency.
  drawImage(image) { if (renderTrace) renderTrace.push({ image: image.src, alpha: this.globalAlpha }); },
  // Marks terrain draws so tests can compare them with both prop rendering passes.
  fillRect() { if (renderTrace && this.fillStyle === "#26342d") renderTrace.push({ terrain: true }); }
}, { get: (target, key) => target[key] ?? (() => {}),
  set: (target, key, value) => { target[key] = value; return true; } });
const nodes = new Map();
for (const match of html.matchAll(/\bid="([^"]+)"/g)) nodes.set(match[1], new Element());
const controls = {};
for (const match of html.matchAll(/data-memory="([^"]+)"/g)) {
  const element = new Element(); element.dataset.memory = match[1]; controls[match[1]] = element;
}
controls.preview.checked = controls.boxes.checked = true; controls.collected.value = "0";

nodes.get("wall-memory-panel").hidden = true;
nodes.get("wall-memory-panel").querySelectorAll = () => Object.values(controls);
const propControls = {};
for (const match of html.matchAll(/data-prop="([^"]+)"/g)) {
  const element = new Element(); element.dataset.prop = match[1]; propControls[match[1]] = element;
}
propControls.visible.checked = propControls.collisions.checked = true;
nodes.get("world-prop-panel").querySelectorAll = () => Object.values(propControls);
const buttons = ["inscriptions", "map", "props"].map(mode => {
  const button = new Element(); button.dataset.editorMode = mode; return button;
});
const document = { getElementById: id => nodes.get(id),
  querySelectorAll: () => buttons, createElement: () => new Element(), activeElement: null };
let online = false, levelReads = 0, heldRead = null;
const disk = new Map(), writes = [];
for (let number = 1; number <= 21; number++) disk.set(number, JSON.stringify({
  width: 10, height: 10, map: Array(10).fill("XXXXXXXXXX"),
  wall_memories: [{ id: "existing_id", x: 32, y: 48, width: 80, role: "regular", text: "Хватит.", min_collected: 0, requires_all_previous: false }]
}));

// Uses real phrase/font metadata and simulates the HTTP save server independently.
async function fetch(url, options = {}) {
  if (url.startsWith("http://127.0.0.1:8000")) {
    if (!online) throw new TypeError("Failed to fetch");
    if (url.endsWith("/api/status")) return { ok: true, json: async () => ({ can_save: true }) };
    const number = Number(/\/(\d+)\.json/.exec(url)[1]);
    disk.set(number, options.body); writes.push({ number, text: options.body });
    return { ok: true };
  }
  if (url.includes("world_props/catalog.json")) {
    return { ok: true, json: async () => JSON.parse(fs.readFileSync(path.join(root, "RandomForest/datafiles/world_props/catalog.json"), "utf8")) };
  }
  if (url.includes("catalog.json")) {
    return { ok: true, json: async () => ({ levels: Array.from({ length: 21 }, (_, i) => i + 1) }) };
  }
  if (url.includes("/narrative/")) {
    const content = JSON.parse(fs.readFileSync(path.join(root, url.replace(/^\.\.\//, "")), "utf8"));
    return { ok: true, json: async () => content };
  }
  levelReads++;
  if (heldRead) { const response = heldRead; heldRead = null; return response; }
  const number = Number(/\/(\d+)\.json/.exec(url)[1]);
  return { ok: true, text: async () => disk.get(number) };
}

const sandbox = vm.createContext({ console, document, fetch, TypeError, AbortController,
  setTimeout, clearTimeout, structuredClone, location: { protocol: "http:" },
  window: { devicePixelRatio: 1, setTimeout, clearTimeout, setInterval() {}, addEventListener() {},
    getComputedStyle: () => ({ paddingLeft: "12px", paddingRight: "12px" }) },
  Image: class {
    // Completes the bundled atlas load without requiring image rendering.
    set src(value) { this._src = value; this.width = this.naturalWidth = 352; this.height = 286; this.complete = true; this.onload(); }
    // Exposes the loaded resource path for rendering-order assertions.
    get src() { return this._src; }
  } });
for (const name of ["forest-enemies.js", "wall-memories.js", "world-props.js", "level-persistence.js"]) {
  vm.runInContext(fs.readFileSync(path.join(root, "visualizer", name), "utf8"), sandbox);
}
vm.runInContext("globalThis.ForestEnemies = window.ForestEnemies", sandbox);
const inline = html.match(/<script>\s*([\s\S]*?)<\/script>/)[1].replace(/\s*initialize\(\);\s*$/, "");
vm.runInContext(inline, sandbox);
const editor = vm.runInContext("({ state, wallEditor, propEditor, persistence, initialize, selectLevel, pollSelectedLevel, undoLastEdit, setEditorMode, renderLevel, drawSymbol })", sandbox);

// Checks that the real page dispatches every forest family to its own distant map cell.
function checkForestEnemyDrawing() {
  for (const symbol of "FfJjCcTtGgWw") {
    const transforms = [];
    const drawing = new Proxy({
      translate(x, y) { transforms.push(["translate", x, y]); },
      scale(x, y) { transforms.push(["scale", x, y]); },
      fillText() { assert.fail("The page must draw enemy icons instead of letters"); }
    }, { get: (target, key) => target[key] ?? (() => {}) });
    editor.drawSymbol(drawing, editor.state.level, symbol, 91, 38);
    const mirrored = symbol === symbol.toLowerCase();
    assert.deepEqual(transforms, [
      ["translate", (91 + (mirrored ? 1 : 0)) * 16, 38 * 16],
      ["scale", mirrored ? -1 : 1, 1]
    ], symbol);
  }
}

// Waits for queued fetch continuations from initialization, loading or UI events.
async function settle() { await new Promise(resolve => setImmediate(resolve)); }

// Reproduces the user's editing failure through the actual page event path.
async function main() {
  await editor.initialize(); await settle();
  checkForestEnemyDrawing();
  editor.selectLevel(11); await settle();
  assert.equal(editor.state.levelNumber, 11);
  assert(!editor.wallEditor.isActive());
  assert(nodes.get("wall-memory-panel").hidden);
  assert(!nodes.get("map-editor-panel").hidden);
  buttons[0].handlers.click();
  assert(editor.wallEditor.isActive());
  assert(!nodes.get("wall-memory-panel").hidden);
  assert(nodes.get("map-editor-panel").hidden);
  assert.equal(buttons[0].attributes["aria-pressed"], "true");
  const pointer = { button: 0, pointerId: 1, clientX: 32, clientY: 48, preventDefault() {} };
  editor.wallEditor.pointerDown(pointer); editor.wallEditor.pointerUp();
  assert.equal(controls.width.value, 80);
  let releaseTextRead;
  heldRead = new Promise(resolve => { releaseTextRead = resolve; });
  const staleTextRead = editor.pollSelectedLevel();
  controls.text.value = "Произвольная фраза\nВторая строка";
  controls.text.handlers.input();
  assert(editor.wallEditor.isEditing());
  releaseTextRead({ ok: true, text: async () => disk.get(11) });
  await staleTextRead;
  assert.equal(controls.text.value, "Произвольная фраза\nВторая строка");
  assert(!controls.text.disabled);
  const beforeTextPoll = levelReads;
  await editor.pollSelectedLevel();
  assert.equal(levelReads, beforeTextPoll);
  assert.equal(controls.text.value, "Произвольная фраза\nВторая строка");
  controls.text.handlers.blur(); await settle();
  assert(!editor.wallEditor.isEditing());
  assert.equal(editor.state.level.wall_memories[0].text, "Произвольная фраза\nВторая строка");
  assert.equal(editor.state.level.wall_memories[0].id, "existing_id");
  // Reset this extra phrase edit before the existing failure/undo scenarios.
  assert(editor.undoLastEdit()); await settle();
  editor.state.undoStack = [];
  editor.wallEditor.pointerDown(pointer); editor.wallEditor.pointerUp();
  controls.width.value = "110"; controls.width.handlers.change();
  assert(nodes.get("retry-save").hidden); // Ordinary in-flight saves never flash retry.
  await settle();
  assert(editor.persistence.hasUnsaved());
  assert(!nodes.get("retry-save").hidden);
  assert(!nodes.get("retry-save").disabled);
  const readsBefore = levelReads;
  for (let i = 0; i < 5; i++) await editor.pollSelectedLevel();
  assert.equal(levelReads, readsBefore);
  assert.equal(editor.state.level.wall_memories[0].width, 110);
  assert.equal(controls.width.value, 110);
  assert(!controls.width.disabled); // Selection survives repeated polling after failure.
  assert.equal(editor.state.undoStack.length, 1);
  editor.selectLevel(12); await settle();
  editor.selectLevel(11); await settle();
  assert.equal(editor.state.level.wall_memories[0].width, 110);
  assert.equal(editor.state.undoStack.length, 1);
  assert(editor.wallEditor.isActive());
  assert(nodes.get("map-editor-panel").hidden);
  online = true;
  await editor.persistence.retry(); await editor.pollSelectedLevel();
  assert(!editor.persistence.hasUnsaved());
  assert(nodes.get("retry-save").hidden);
  assert.equal(JSON.parse(writes.at(-1).text).wall_memories[0].width, 110);
  assert.equal(editor.state.undoStack.length, 1);
  editor.wallEditor.pointerDown(pointer); editor.wallEditor.pointerUp();
  controls.width.value = "120"; controls.width.handlers.change();
  assert(nodes.get("retry-save").hidden);
  await settle();
  assert(nodes.get("retry-save").hidden);
  await editor.pollSelectedLevel();
  assert.equal(controls.width.value, 120);
  assert(!controls.width.disabled); // Successful autosave also retains selection.
  assert.equal(editor.state.undoStack.length, 2);
  assert(editor.undoLastEdit()); await settle();
  assert.equal(editor.state.level.wall_memories[0].width, 110);
  editor.wallEditor.pointerDown({ ...pointer, clientX: 119, clientY: 119 });
  assert(editor.wallEditor.isDragging());
  buttons[1].handlers.click(); await settle();
  assert(!editor.wallEditor.isDragging());
  assert(!editor.wallEditor.isActive());
  assert(nodes.get("wall-memory-panel").hidden);
  assert(!nodes.get("map-editor-panel").hidden);
  assert.equal(editor.state.level.wall_memories[0].id, "existing_id");
  assert.equal(editor.state.level.wall_memories[1].id, "memory_1");
  assert.equal(editor.state.level.map[0], "XXXXXXXXXX");
  // A read already in flight must not replace a newer unsaved map gesture.
  let releaseRead;
  heldRead = new Promise(resolve => { releaseRead = resolve; });
  const staleRead = editor.pollSelectedLevel();
  online = false;
  nodes.get("map-canvas").handlers.pointerdown({ ...pointer, clientX: 5, clientY: 5 });
  nodes.get("map-canvas").handlers.pointerup(); await settle();
  releaseRead({ ok: true, text: async () => disk.get(11) });
  await staleRead;
  assert.equal(editor.state.level.map[0], ".XXXXXXXXX");
  assert(editor.persistence.hasUnsaved());
  assert(!nodes.get("retry-save").hidden);
  assert.equal(editor.state.level.wall_memories[0].id, "existing_id");
  online = true;
  await editor.persistence.retry();
  assert.equal(JSON.parse(writes.at(-1).text).map[0], ".XXXXXXXXX");
  assert(!html.includes('data-memory="id"'));
  // Prop placement and local collision strokes share the real page's save/undo route.
  editor.setEditorMode("props");
  assert(editor.propEditor.isActive());
  assert(nodes.get("map-editor-panel").hidden);
  assert.equal(propControls.palette.children.length, 19);
  const mapBefore = [...editor.state.level.map];
  const memoriesBefore = JSON.stringify(editor.state.level.wall_memories);
  const canvas = nodes.get("map-canvas");
  propControls.palette.children[18].handlers.click();
  canvas.handlers.pointerdown({ ...pointer, clientX: 60, clientY: 60 });
  const readsDuringPlacement = levelReads;
  await editor.pollSelectedLevel();
  assert.equal(levelReads, readsDuringPlacement);
  canvas.handlers.pointerup(); await settle();
  assert.equal(editor.state.level.props.length, 1);
  assert.equal(editor.state.level.props[0].type, "morning_table");
  assert.equal(editor.state.level.props[0].x, 60);
  assert.equal(propControls.opacity.value, "100");
  assert.equal(propControls.platform_layer.value, "above");
  assert(editor.undoLastEdit()); await settle();
  assert(!Object.hasOwn(editor.state.level, "props"));
  propControls.palette.children[18].handlers.click();
  canvas.handlers.pointerdown({ ...pointer, clientX: 60, clientY: 60 });
  canvas.handlers.pointerup(); await settle();
  // Per-instance appearance changes share undo and preserve the physical cells.
  propControls.opacity.value = "35"; propControls.opacity.handlers.change(); await settle();
  assert.equal(editor.state.level.props[0].opacity, 35);
  assert(editor.undoLastEdit()); await settle();
  assert.equal(propControls.opacity.value, "100");
  propControls.opacity.value = "0"; propControls.opacity.handlers.change(); await settle();
  assert.equal(editor.state.level.props[0].opacity, 0);
  assert(editor.undoLastEdit()); await settle();
  propControls.opacity.value = "35"; propControls.opacity.handlers.change(); await settle();
  propControls.platform_layer.value = "below"; propControls.platform_layer.handlers.change(); await settle();
  assert.equal(editor.state.level.props[0].platform_layer, "below");
  assert(editor.undoLastEdit()); await settle();
  assert.equal(propControls.platform_layer.value, "above");
  propControls.platform_layer.value = "below"; propControls.platform_layer.handlers.change(); await settle();
  propControls.solids.handlers.click();
  const historyBeforeStroke = editor.state.undoStack.length;
  canvas.handlers.pointerdown({ ...pointer, clientX: 61, clientY: 61 });
  canvas.handlers.pointermove({ ...pointer, clientX: 67, clientY: 61 });
  canvas.handlers.pointerup(); await settle();
  assert.equal(editor.state.undoStack.length, historyBeforeStroke + 1);
  assert.equal(editor.state.level.props[0].solids.length, 2);
  canvas.handlers.pointerdown({ ...pointer, button: 2, clientX: 61, clientY: 61 });
  canvas.handlers.pointerup(); await settle();
  assert.equal(editor.state.level.props[0].solids.length, 1);
  assert(editor.undoLastEdit()); await settle();
  assert.equal(editor.state.level.props[0].solids.length, 2);
  // Painting one-way support replaces solid cells atomically, within this group only.
  propControls.collision_type.value = "jump_thrus"; propControls.collision_type.handlers.change();
  canvas.handlers.pointerdown({ ...pointer, clientX: 61, clientY: 61 });
  canvas.handlers.pointerup(); await settle();
  assert.equal(editor.state.level.props[0].solids.length, 1);
  assert.equal(editor.state.level.props[0].jump_thrus.length, 1);
  assert(editor.undoLastEdit()); await settle();
  assert.equal(editor.state.level.props[0].solids.length, 2);
  assert(!Object.hasOwn(editor.state.level.props[0], "jump_thrus"));
  canvas.handlers.pointerdown({ ...pointer, clientX: 61, clientY: 67 });
  canvas.handlers.pointermove({ ...pointer, clientX: 67, clientY: 67 });
  canvas.handlers.pointerup(); await settle();
  assert.equal(editor.state.level.props[0].jump_thrus.length, 2);
  assert.equal(editor.state.level.props[0].solids.length, 2);
  canvas.handlers.pointerdown({ ...pointer, button: 2, clientX: 61, clientY: 67 });
  canvas.handlers.pointerup(); await settle();
  assert.equal(editor.state.level.props[0].jump_thrus.length, 1);
  assert.equal(editor.state.level.props[0].solids.length, 2);
  assert(editor.undoLastEdit()); await settle();
  const localJumpCells = JSON.stringify(editor.state.level.props[0].jump_thrus);
  propControls.collision_type.value = "solids"; propControls.collision_type.handlers.change();
  const localCells = JSON.stringify(editor.state.level.props[0].solids);
  propControls.move.handlers.click();
  canvas.handlers.pointerdown({ ...pointer, clientX: 60, clientY: 60 });
  canvas.handlers.pointermove({ ...pointer, clientX: 72, clientY: 66 });
  canvas.handlers.pointerup(); await settle();
  assert.equal(editor.state.level.props[0].x, 72);
  assert.equal(editor.state.level.props[0].y, 66);
  assert.equal(JSON.stringify(editor.state.level.props[0].solids), localCells);
  assert.equal(JSON.stringify(editor.state.level.props[0].jump_thrus), localJumpCells);
  assert(editor.undoLastEdit()); await settle();
  assert.equal(editor.state.level.props[0].x, 60);
  propControls.mirror.handlers.click(); await settle();
  assert(editor.state.level.props[0].mirrored);
  assert.equal(JSON.stringify(editor.state.level.props[0].solids), localCells);
  assert.equal(JSON.stringify(editor.state.level.props[0].jump_thrus), localJumpCells);
  propControls.duplicate.handlers.click(); await settle();
  assert.equal(editor.state.level.props.length, 2);
  assert.notEqual(editor.state.level.props[0].id, editor.state.level.props[1].id);
  assert.equal(editor.state.level.props[1].opacity, 35);
  assert.equal(editor.state.level.props[1].platform_layer, "below");
  assert.equal(JSON.stringify(editor.state.level.props[1].solids), localCells);
  assert.equal(JSON.stringify(editor.state.level.props[1].jump_thrus), localJumpCells);
  propControls.opacity.value = "80"; propControls.opacity.handlers.change(); await settle();
  propControls.platform_layer.value = "above"; propControls.platform_layer.handlers.change(); await settle();
  assert.equal(editor.state.level.props[0].opacity, 35);
  assert.equal(editor.state.level.props[0].platform_layer, "below");
  renderTrace = [];
  editor.renderLevel();
  const belowDraw = renderTrace.findIndex(call => call.image?.includes("sWorldPropMorningTable") && call.alpha === 0.35);
  const terrainDraw = renderTrace.findIndex(call => call.terrain);
  const aboveDraw = renderTrace.findIndex(call => call.image?.includes("sWorldPropMorningTable") && call.alpha === 0.8);
  assert(belowDraw >= 0 && belowDraw < terrainDraw && terrainDraw < aboveDraw);
  renderTrace = null;
  propControls.delete.handlers.click(); await settle();
  assert.equal(editor.state.level.props.length, 1);
  assert(editor.undoLastEdit()); await settle();
  assert.equal(editor.state.level.props.length, 2);
  assert.deepEqual([...editor.state.level.map], mapBefore);
  assert.equal(JSON.stringify(editor.state.level.wall_memories), memoriesBefore);
  // A failed prop write retains the entire group across navigation and retry.
  online = false;
  propControls.mirror.handlers.click(); await settle();
  const propDraft = JSON.stringify(editor.state.level.props);
  editor.selectLevel(12); await settle(); editor.selectLevel(11); await settle();
  assert.equal(JSON.stringify(editor.state.level.props), propDraft);
  propControls.instances.children[0].handlers.click();
  assert.equal(propControls.opacity.value, "35");
  assert.equal(propControls.platform_layer.value, "below");
  online = true; await editor.persistence.retry();
  assert.equal(JSON.stringify(JSON.parse(writes.at(-1).text).props), propDraft);
  // Switching modes finishes a live prop drag once before map painting takes over.
  propControls.instances.children[1].handlers.click();
  canvas.handlers.pointerdown({ ...pointer, clientX: 60, clientY: 60 });
  canvas.handlers.pointermove({ ...pointer, clientX: 66, clientY: 66 });
  assert(editor.propEditor.isEditing());
  editor.setEditorMode("map");
  await settle();
  assert(!editor.propEditor.isEditing());
  assert(!editor.propEditor.isActive());
  const mapPanel = html.slice(html.indexOf('<div id="map-editor-panel">'), html.indexOf("</aside>"));
  assert(mapPanel.indexOf("Объекты и блоки") < mapPanel.indexOf("Параметры"));
  assert(mapPanel.indexOf("Параметры") < mapPanel.indexOf("Обозначения"));
  console.log("Actual page: failure/poll selection, draft navigation, retry, undo, exclusive panels, gesture completion and stale-read protection passed.");
}

main().catch(error => { console.error(error); process.exitCode = 1; });
