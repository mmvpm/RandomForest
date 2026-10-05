"use strict";

// Keeps inscription geometry and phrase filtering independent from the editor UI.
const WallMemoryModel = {
  // Returns the same world rectangle for drawing and pointer hit testing.
  bounds(anchor, height = 60) {
    return { left: anchor.align === "right" ? anchor.x - anchor.width : anchor.x,
      top: anchor.y, width: anchor.width, height };
  },
  // Converts CSS-scaled pointer coordinates into integer world pixels.
  point(event, bounds, width, height) {
    return { x: Math.round((event.clientX - bounds.left) / bounds.width * width),
      y: Math.round((event.clientY - bounds.top) / bounds.height * height) };
  },
  // Filters ordinary phrases by the campaign number and collected memories.
  eligible(config, level, collected) {
    return (config.phrases || []).filter(phrase =>
      level >= (phrase.from_level ?? 1) && level <= (phrase.to_level ?? 40) &&
      collected >= (phrase.min_collected ?? 0) &&
      (!phrase.requires_all_previous || collected >= level - 1));
  },
  // Matches the game's local hash without changing its random-number stream.
  hash(level, id, collected) {
    let hash = 0;
    for (const character of `${level}:${id}:${collected}`) {
      hash = (hash * 31 + character.codePointAt(0)) % 2147483647;
    }
    return hash;
  },
  // Assigns eligible phrases once in stable anchor-ID order without repeats.
  assign(config, anchors, level, collected, missing) {
    const pool = this.eligible(config, level, collected)
      .filter(phrase => !phrase.requires_all_previous || !missing);
    const used = new Set(), assigned = new Map();
    for (const item of [...anchors].sort((a, b) => a.id < b.id ? -1 : a.id > b.id ? 1 : 0)) {
      if (item.role !== "regular") continue;
      const available = pool.filter(value => !used.has(value.id));
      const explicit = item.text_id && available.find(value => value.id === item.text_id);
      const phrase = item.text_id ? explicit : available[this.hash(level, item.id, collected) % Math.max(1, available.length)];
      if (phrase) { used.add(phrase.id); assigned.set(item.id, phrase); }
    }
    return assigned;
  },
  // Wraps handwritten text using measured words and explicit line breaks.
  wrap(context, text, width) {
    const lines = [];
    for (const paragraph of text.split("\n")) {
      let line = "";
      for (const word of paragraph.split(/\s+/)) {
        const candidate = line ? `${line} ${word}` : word;
        if (line && context.measureText(candidate).width > width) {
          lines.push(line); line = word;
        } else line = candidate;
      }
      lines.push(line);
    }
    return lines;
  }
};

// Owns only wall anchors; map painting and saving remain with the existing editor.
function createWallMemoryEditor({ state, canvas, render, save, hideTooltip }) {
  const panel = document.getElementById("wall-memory-panel");
  const controls = Object.fromEntries([...panel.querySelectorAll("[data-memory]")]
    .map(element => [element.dataset.memory, element]));
  let mode = false;
  let selected = -1;
  let drag = null;
  let config = { phrases: [], special: {}, styles: {} };
  let previewText = "";
  let alphabet = null, atlas = null;
  const tinted = new Map();
  const makePicker = typeof module !== "undefined" ? require("./phrase-picker.js").createPhrasePicker : createPhrasePicker;
  const phrasePicker = makePicker({ input: controls.text_id, list: controls.text_ids,
    getValue: () => anchor()?.text_id || "", onSelect: () => changeField("text_id"),
    onInvalid: () => { controls.message.textContent = "Выберите фразу из списка. Произвольный текст доступен только в пробном превью."; } });

  // Returns the selected anchor without introducing arrays into legacy levels.
  function anchor() { return state.level?.wall_memories?.[selected]; }
  // Captures an undo snapshot without changing absent optional properties.
  function remember() {
    return { kind: "wall_memories", value: state.level.wall_memories === undefined
      ? undefined : structuredClone(state.level.wall_memories) };
  }
  // Commits one complete gesture through the original ordered save queue.
  function commit(snapshot) {
    if (snapshot) state.undoStack.push(snapshot);
    state.editRevision += 1;
    render(); refresh(); save();
  }
  // Maps the pointer to the map's original world-pixel dimensions.
  function point(event) {
    return WallMemoryModel.point(event, canvas.getBoundingClientRect(),
      state.level.width * 12, state.level.height * 12);
  }
  // Chooses a representative eligible phrase; explicit text IDs remain stable.
  function textFor(item, index) {
    if (index === selected && previewText) return previewText;
    if (item.role === "missing_previous") {
      return controls.missing.checked ? config.special.text || "Предыдущая память пропущена" : "";
    }
    const assigned = WallMemoryModel.assign(config, state.level.wall_memories,
      state.levelNumber + 10, Number(controls.collected.value), controls.missing.checked);
    return assigned.get(item.id)?.text || "";
  }
  // Resolves configurable handwritten style values without affecting saved geometry.
  function styleFor(item) {
    const level = state.levelNumber + 10;
    const phase = level <= 20 ? "day" : level <= 30 ? "evening" : level <= 40 ? "night" : "morning";
    const defaults = config.defaults || {};
    const rgb = config.styles?.[phase] || [206, 193, 170];
    return { size: defaults.font_size ?? 18,
      lineHeight: defaults.line_height ?? 20, alpha: defaults.opacity ?? 0.9,
      color: `rgb(${rgb.join(",")})` };
  }
  // Measures words with the same proportional glyph advances as GameMaker.
  function measure(text) {
    if (!alphabet) return 0;
    return Array.from(text).reduce((width, character) =>
      width + (alphabet.advances[alphabet.characters.indexOf(character)] || 0), 0);
  }
  // Uses the game's padding, whole-pixel alignment and line spacing.
  function layout(context, item, index) {
    const style = styleFor(item);
    const lines = WallMemoryModel.wrap({ measureText: text => ({ width: measure(text) }) },
      textFor(item, index), item.width - 6);
    const width = Math.ceil(item.width);
    return { style, lines, box: { left: Math.round(item.x) - (item.align === "right" ? width : 0),
      top: Math.round(item.y), width, height: 32 + (lines.length - 1) * style.lineHeight } };
  }
  // Caches a colour variant without changing the glyph's four alpha steps.
  function colourAtlas(colour) {
    if (tinted.has(colour)) return tinted.get(colour);
    const image = document.createElement("canvas"); image.width = atlas.width; image.height = atlas.height;
    const context = image.getContext("2d"); context.drawImage(atlas, 0, 0);
    context.globalCompositeOperation = "source-in"; context.fillStyle = colour;
    context.fillRect(0, 0, image.width, image.height); tinted.set(colour, image); return image;
  }
  // Draws each cropped glyph at its original baseline with proportional spacing.
  function drawLine(context, line, x, y, colour, highlight = "") {
    const at = highlight ? line.indexOf(highlight) : -1;
    let cursor = x, offset = 0;
    for (const character of line) {
      const index = alphabet.characters.indexOf(character);
      if (index < 0) continue;
      const bounds = alphabet.glyph_bounds[index];
      const accent = at >= 0 && offset >= at && offset < at + highlight.length;
      const ink = accent ? `rgb(${config.special.highlight_colour.join(",")})` : colour;
      if (character !== " ") context.drawImage(colourAtlas(ink),
        index % alphabet.atlas.columns * alphabet.atlas.cell_width + bounds[0],
        Math.floor(index / alphabet.atlas.columns) * alphabet.atlas.cell_height + bounds[1],
        bounds[2] - bounds[0], bounds[3] - bounds[1], cursor, y + bounds[1],
        bounds[2] - bounds[0], bounds[3] - bounds[1]);
      cursor += alphabet.advances[index]; offset += character.length;
    }
  }
  // Shows the actual sprite font plus optional authoring bounds in world pixels.
  function draw(context) {
    if (!state.level) return;
    context.save(); context.imageSmoothingEnabled = false;
    (state.level.wall_memories || []).forEach((item, index) => {
      const { style, lines, box } = layout(context, item, index);
      if (controls.preview.checked && alphabet && atlas) {
        context.globalAlpha = style.alpha * 0.8;
        lines.forEach((line, row) => {
          for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) {
            if (dx || dy) drawLine(context, line, box.left + 3 + dx,
              box.top + 3 + row * style.lineHeight + dy, "black");
          }
        });
        context.globalAlpha = style.alpha;
        lines.forEach((line, row) => drawLine(context, line, box.left + 3,
          box.top + 3 + row * style.lineHeight, style.color,
          item.role === "missing_previous" ? config.special.highlight_word : ""));
      }
      if (mode && controls.boxes.checked) {
        context.globalAlpha = 1;
        context.strokeStyle = index === selected ? "#ffd57b" : "#90b8b2";
        context.lineWidth = 1; context.setLineDash(index === selected ? [] : [4, 3]);
        context.strokeRect(box.left + 0.5, box.top + 0.5, box.width, box.height);
        context.fillStyle = context.strokeStyle; context.fillRect(item.x - 2, item.y - 2, 4, 4);
      }
    });
    context.restore();
  }
  // Synchronizes anchor controls after selections, undo and external JSON reloads.
  function refresh(reset = false) {
    if (reset) { selected = -1; drag = null; previewText = ""; controls.sample.value = ""; phrasePicker.close(); }
    const item = anchor();
    for (const name of ["align", "width", "role", "text_id", "delete"]) controls[name].disabled = !item;
    for (const name of ["align", "width", "role", "text_id"]) controls[name].value = item?.[name] ?? (name === "width" ? 168 : "");
    controls.position.textContent = item ? `x: ${item.x} · y: ${item.y} · уровень игры: ${state.levelNumber + 10}` : "Нажмите на карту, чтобы добавить надпись";
  }
  // Starts moving a hit anchor, or creates a new optional anchor at the pointer.
  function pointerDown(event) {
    if (!mode) return false;
    if (event.button !== 0 || !state.level || !state.loadedPath) return true;
    hideTooltip(); canvas.focus({ preventScroll: true });
    const position = point(event);
    const snapshot = remember();
    const context = canvas.getContext("2d");
    const items = state.level.wall_memories || [];
    selected = items.findLastIndex((item, index) => {
      const { box } = layout(context, item, index);
      return position.x >= box.left && position.x <= box.left + box.width &&
        position.y >= box.top && position.y <= box.top + box.height;
    });
    if (selected < 0) {
      const used = new Set(items.map(item => item.id));
      let number = 1;
      while (used.has(`memory_${number}`)) number += 1;
      const item = { id: `memory_${number}`, ...position, align: "left", width: 168, role: "regular", text_id: "" };
      if (!state.level.wall_memories) state.level.wall_memories = [];
      state.level.wall_memories.push(item);
      selected = state.level.wall_memories.length - 1;
    }
    const item = anchor();
    drag = { snapshot, offsetX: position.x - item.x, offsetY: position.y - item.y,
      changed: JSON.stringify(snapshot.value) !== JSON.stringify(state.level.wall_memories) };
    canvas.setPointerCapture(event.pointerId);
    refresh(); render(); event.preventDefault();
    return true;
  }
  // Moves a selected anchor without painting or saving intermediate mouse positions.
  function pointerMove(event) {
    if (!mode) return false;
    if (!drag || !state.level) return true;
    const position = point(event), item = anchor();
    const x = Math.max(0, Math.min(state.level.width * 12, position.x - drag.offsetX));
    const y = Math.max(0, Math.min(state.level.height * 12, position.y - drag.offsetY));
    if (x !== item.x || y !== item.y) { item.x = x; item.y = y; drag.changed = true; render(); refresh(); }
    return true;
  }
  // Saves the whole creation or drag as one undoable edit.
  function pointerUp() {
    if (!mode) return false;
    if (drag) { const gesture = drag; drag = null; if (gesture.changed) commit(gesture.snapshot); }
    return true;
  }
  // Deletes only the selected anchor and retains all other level settings.
  function remove() {
    if (!anchor()) return;
    const snapshot = remember(); state.level.wall_memories.splice(selected, 1); selected = -1; commit(snapshot);
  }
  // Restores the optional anchor array exactly, including its original absence.
  function undo(edit) {
    if (edit.kind !== "wall_memories") return false;
    if (edit.value === undefined) delete state.level.wall_memories;
    else state.level.wall_memories = structuredClone(edit.value);
    selected = -1; drag = null; commit(); return true;
  }
  // Prevents mode-specific keyboard actions from rotating map tiles.
  function keyboard(event) {
    if (!mode) return false;
    if (event.key === "Delete" || event.key === "Backspace") { remove(); event.preventDefault(); }
    return event.code === "KeyR" || event.key === "Delete" || event.key === "Backspace";
  }
  // Changes only one explicitly edited anchor field.
  function changeField(name) {
    const item = anchor(); if (!item) return;
    let value = controls[name].value;
    if (name === "width") value = Math.max(16, Math.round(Number(value) || 168));
    if (value === item[name]) return;
    const snapshot = remember(); item[name] = value; commit(snapshot);
  }
  // Loads preview phrases and waits for the bundled font before drawing.
  async function load() {
    try {
      const response = await fetch("../RandomForest/datafiles/narrative/wall_memories.json", { cache: "no-store" });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      config = await response.json();
      const fontResponse = await fetch("../RandomForest/datafiles/narrative/memory_font.json", { cache: "no-store" });
      if (!fontResponse.ok) throw new Error(`HTTP ${fontResponse.status}`);
      alphabet = await fontResponse.json();
      atlas = await new Promise((resolve, reject) => {
        const image = new Image(); image.onload = () => resolve(image); image.onerror = reject;
        image.src = "../RandomForest/datafiles/" + alphabet.atlas.file;
      });
      phrasePicker.setOptions(config.phrases || []);
      controls.message.textContent = "Фразы и шрифт из настроек игры";
    } catch (error) { controls.message.textContent = `Превью фраз недоступно: ${error.message}`; }
    render();
  }
  // Finishes the current anchor gesture before changing the shared editor mode.
  function setActive(active) {
    pointerUp(); mode = active; phrasePicker.close(); hideTooltip(); refresh(); render();
  }
  controls.delete.addEventListener("click", remove);
  for (const name of ["align", "width", "role"]) controls[name].addEventListener("change", () => changeField(name));
  for (const name of ["preview", "boxes", "missing", "collected"]) controls[name].addEventListener("input", () => { controls.count.textContent = controls.collected.value; render(); });
  controls.sample.addEventListener("input", () => { previewText = controls.sample.value; render(); });
  refresh(); load();
  return { draw, refresh, pointerDown, pointerMove, pointerUp, undo, keyboard, setActive,
    isDragging: () => Boolean(drag), isActive: () => mode };
}

if (typeof module !== "undefined") module.exports = { WallMemoryModel, createWallMemoryEditor };
