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

const context = new Proxy({}, { get: (target, key) => target[key] ?? (() => {}),
  set: (target, key, value) => { target[key] = value; return true; } });
const nodes = new Map();
for (const match of html.matchAll(/\bid="([^"]+)"/g)) nodes.set(match[1], new Element());
const controls = {};
for (const match of html.matchAll(/data-memory="([^"]+)"/g)) {
  const element = new Element(); element.dataset.memory = match[1]; controls[match[1]] = element;
}
controls.preview.checked = controls.boxes.checked = true; controls.collected.value = "0";
controls.text_ids.id = "wall-text-ids";
nodes.get("wall-memory-panel").hidden = true;
nodes.get("wall-memory-panel").querySelectorAll = () => Object.values(controls);
const buttons = ["inscriptions", "map"].map(mode => {
  const button = new Element(); button.dataset.editorMode = mode; return button;
});
const document = { getElementById: id => nodes.get(id),
  querySelectorAll: () => buttons, createElement: () => new Element(), activeElement: null };
let online = false, levelReads = 0, heldRead = null;
const disk = new Map(), writes = [];
for (let number = 1; number <= 21; number++) disk.set(number, JSON.stringify({
  width: 10, height: 10, map: Array(10).fill("XXXXXXXXXX"),
  wall_memories: [{ id: "existing_id", x: 32, y: 48, align: "left", width: 80, role: "regular", text_id: "" }]
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
    set src(value) { this.width = 352; this.height = 286; this.onload(); }
  } });
for (const name of ["phrase-picker.js", "wall-memories.js", "level-persistence.js"]) {
  vm.runInContext(fs.readFileSync(path.join(root, "visualizer", name), "utf8"), sandbox);
}
const inline = html.match(/<script>\s*([\s\S]*?)<\/script>/)[1].replace(/\s*initialize\(\);\s*$/, "");
vm.runInContext(inline, sandbox);
const editor = vm.runInContext("({ state, wallEditor, persistence, initialize, selectLevel, pollSelectedLevel, undoLastEdit })", sandbox);

// Waits for queued fetch continuations from initialization, loading or UI events.
async function settle() { await new Promise(resolve => setImmediate(resolve)); }

// Reproduces the user's editing failure through the actual page event path.
async function main() {
  await editor.initialize(); await settle();
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
  controls.text_id.handlers.focus();
  assert(!controls.text_ids.hidden);
  controls.text_id.value = "Хватит"; controls.text_id.handlers.input();
  const phrase = controls.text_ids.children.find(button => button.textContent.includes("memory_21_05"));
  assert(phrase);
  assert(phrase.textContent.includes("Хватит"));
  phrase.handlers.click(); await settle();
  assert.equal(editor.state.level.wall_memories[0].text_id, "memory_21_05");
  assert(controls.text_ids.hidden);
  controls.text_id.handlers.focus();
  controls.text_id.handlers.keydown({ key: "ArrowDown", preventDefault() {} });
  controls.text_id.handlers.keydown({ key: "ArrowDown", preventDefault() {} });
  assert.equal(controls.text_id.attributes["aria-activedescendant"], "wall-text-ids-option-1");
  controls.text_id.handlers.keydown({ key: "Enter", preventDefault() {} });
  assert.equal(editor.state.level.wall_memories[0].text_id, "memory_21_05");
  controls.text_id.value = "Поисковая строка"; controls.text_id.handlers.input();
  controls.text_id.handlers.keydown({ key: "Escape", preventDefault() {} });
  assert(controls.text_ids.hidden);
  assert.equal(controls.text_id.value, "memory_21_05");
  controls.text_id.value = "Произвольная новая фраза"; controls.text_id.handlers.change();
  assert.equal(controls.text_id.value, "memory_21_05");
  assert.equal(editor.state.level.wall_memories[0].text_id, "memory_21_05");
  assert(controls.message.textContent.includes("пробном превью"));
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
  const mapPanel = html.slice(html.indexOf('<div id="map-editor-panel">'), html.indexOf("</aside>"));
  assert(mapPanel.indexOf("Объекты и блоки") < mapPanel.indexOf("Параметры"));
  assert(mapPanel.indexOf("Параметры") < mapPanel.indexOf("Обозначения"));
  console.log("Actual page: failure/poll selection, draft navigation, retry, undo, exclusive panels, gesture completion and stale-read protection passed.");
}

main().catch(error => { console.error(error); process.exitCode = 1; });
