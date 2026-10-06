"use strict";

// Keeps centred inscription geometry and progress conditions independent from the UI.
const WallMemoryModel = {
  // Returns the fixed centred block used for rendering and hit testing.
  bounds(anchor, height = 36) {
    const width = Math.max(32, Math.ceil(anchor.width));
    return { left: Math.round(anchor.x - width / 2), top: Math.round(anchor.y - height / 2), width, height };
  },
  // Converts CSS-scaled pointer coordinates into integer world pixels.
  point(event, bounds, width, height) {
    return { x: Math.round((event.clientX - bounds.left) / bounds.width * width),
      y: Math.round((event.clientY - bounds.top) / bounds.height * height) };
  },
  // Matches the fixed place's room-entry progress conditions.
  eligible(anchor, level, collected, missing) {
    return collected >= (anchor.min_collected ?? 0) &&
      (!anchor.requires_all_previous || (!missing && collected >= level - 1)) &&
      (anchor.role !== "missing_previous" || missing);
  },
  // Matches GameMaker's palette hash without consuming gameplay randomness.
  hash(level, id) {
    let hash = 0;
    for (const character of `${level}:${id}`) hash = (hash * 31 + character.codePointAt(0)) % 2147483647;
    return hash;
  },
  // Wraps handwritten text using measured words and explicit line breaks.
  wrap(context, text, width) {
    const lines = [];
    for (const paragraph of text.split("\n")) {
      let line = "";
      for (const word of paragraph.split(" ")) {
        const candidate = line ? `${line} ${word}` : word;
        if (line && context.measureText(candidate).width > width) { lines.push(line); line = word; }
        else line = candidate;
        while (context.measureText(line).width > width) {
          const letters = Array.from(line);
          let cut = 1;
          while (cut < letters.length && context.measureText(letters.slice(0, cut + 1).join("")).width <= width) cut++;
          lines.push(letters.slice(0, cut).join("")); line = letters.slice(cut).join("");
        }
      }
      if (line || !paragraph) lines.push(line);
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
  let config = { special: {}, palette: [] };
  let textEdit = null;
  let alphabet = null, atlas = null;
  const tinted = new Map();

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
  // Uses the textarea draft while keeping the saved anchor unchanged until commit.
  function textFor(item, index) { return index === selected && textEdit ? controls.text.value : item.text || ""; }
  // Chooses one stable colour for the place, independent of campaign phase.
  function styleFor(item) {
    const defaults = config.defaults || {};
    const palette = config.palette?.length ? config.palette : [[206, 193, 170]];
    const rgb = palette[WallMemoryModel.hash(state.levelNumber + 10, item.id) % palette.length];
    return { lineHeight: defaults.line_height ?? 24, alpha: defaults.opacity ?? 1,
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
    const width = Math.max(32, Math.ceil(item.width));
    const lines = WallMemoryModel.wrap({ measureText: text => ({ width: measure(text) }) }, textFor(item, index), width - 6);
    const height = (alphabet?.glyph_height ?? 30) + 6 + Math.max(0, lines.length - 1) * style.lineHeight;
    return { style, lines, box: WallMemoryModel.bounds(item, height),
      lineX: lines.map(line => Math.round((width - measure(line)) / 2)) };
  }

  // Caches a colour variant of the original glyph atlas.
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
      const { style, lines, box, lineX } = layout(context, item, index);
      if (controls.preview.checked && alphabet && atlas && WallMemoryModel.eligible(item,
        state.levelNumber + 10, Number(controls.collected.value), controls.missing.checked)) {
        context.globalAlpha = style.alpha * 0.8;
        lines.forEach((line, row) => {
          for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) {
            if (dx || dy) drawLine(context, line, box.left + lineX[row] + dx,
              box.top + 3 + row * style.lineHeight + dy, "black");
          }
        });
        context.globalAlpha = style.alpha;
        lines.forEach((line, row) => drawLine(context, line, box.left + lineX[row],
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
    if (reset) { selected = -1; drag = null; textEdit = null; }
    const item = anchor();
    for (const name of ["width", "role", "text", "min_collected", "delete"]) controls[name].disabled = !item;
    for (const name of ["width", "text", "min_collected"]) {
      if (name === "text" && textEdit) continue;
      controls[name].value = item?.[name] ?? (name === "width" ? 168 : name === "min_collected" ? 0 : "");
    }
    controls.role.value = item?.requires_all_previous ? "all_previous" : item?.role || "regular";
    controls.position.textContent = item ? `x: ${item.x} · y: ${item.y} · уровень игры: ${state.levelNumber + 10}` : "Нажмите на карту, чтобы добавить надпись";
  }
  // Starts moving a hit anchor, or creates a new optional anchor at the pointer.
  function pointerDown(event) {
    if (!mode) return false;
    if (event.button !== 0 || !state.level || !state.loadedPath) return true;
    finishTextEdit(); hideTooltip(); canvas.focus({ preventScroll: true });
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
      const item = { id: `memory_${number}`, ...position, width: 168, role: "regular", text: "", min_collected: 0, requires_all_previous: false };
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
    finishTextEdit();
    if (!mode) return false;
    if (drag) { const gesture = drag; drag = null; if (gesture.changed) commit(gesture.snapshot); }
    return true;
  }
  // Deletes only the selected anchor and retains all other level settings.
  function remove() {
    finishTextEdit();
    if (!anchor()) return;
    const snapshot = remember(); state.level.wall_memories.splice(selected, 1); selected = -1; commit(snapshot);
  }
  // Restores the optional anchor array exactly, including its original absence.
  function undo(edit) {
    if (edit.kind !== "wall_memories") return false;
    if (edit.value === undefined) delete state.level.wall_memories;
    else state.level.wall_memories = structuredClone(edit.value);
    selected = -1; drag = null; textEdit = null; commit(); return true;
  }
  // Prevents mode-specific keyboard actions from rotating map tiles.
  function keyboard(event) {
    if (!mode) return false;
    if (event.key === "Delete" || event.key === "Backspace") { remove(); event.preventDefault(); }
    return event.code === "KeyR" || event.key === "Delete" || event.key === "Backspace";
  }
  // Keeps typing as one gesture and prevents live polling from replacing the draft.
  function editText() {
    if (!anchor()) return;
    if (!textEdit) { textEdit = remember(); state.editRevision++; }
    render();
  }
  // Commits the full textarea value once on blur or before changing selections.
  function finishTextEdit() {
    if (!textEdit) return;
    const snapshot = textEdit, item = anchor(); textEdit = null;
    if (item && item.text !== controls.text.value) { item.text = controls.text.value; commit(snapshot); }
    else { refresh(); render(); }
  }
  // Changes a size or condition while keeping each gesture separately undoable.
  function changeField(name) {
    finishTextEdit();
    const item = anchor(); if (!item) return;
    let value = controls[name].value;
    if (name === "width") value = Math.max(32, Math.round(Number(value) || 168));
    if (name === "min_collected") value = Math.max(0, Math.floor(Number(value) || 0));
    if (name === "role") {
      const role = value === "all_previous" ? "regular" : value;
      const all = value === "all_previous";
      if (role === item.role && all === Boolean(item.requires_all_previous)) return;
      const snapshot = remember(); item.role = role; item.requires_all_previous = all; commit(snapshot); return;
    }
    if (value === item[name]) return;
    const snapshot = remember(); item[name] = value; commit(snapshot);
  }
  // Loads shared visual settings and the exact bundled glyph atlas.
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
      controls.message.textContent = "Текст сохраняется в JSON уровня. Переносы строк поддерживаются.";
    } catch (error) { controls.message.textContent = `Превью шрифта недоступно: ${error.message}`; }
    render();
  }
  // Finishes the current anchor gesture before changing the shared editor mode.
  function setActive(active) {
    pointerUp(); mode = active; hideTooltip(); refresh(); render();
  }
  controls.delete.addEventListener("click", remove);
  for (const name of ["width", "role", "min_collected"]) controls[name].addEventListener("change", () => changeField(name));
  for (const name of ["preview", "boxes", "missing", "collected"]) controls[name].addEventListener("input", () => { controls.count.textContent = controls.collected.value; render(); });
  controls.text.addEventListener("input", editText);
  controls.text.addEventListener("change", finishTextEdit);
  controls.text.addEventListener("blur", finishTextEdit);
  refresh(); load();
  return { draw, refresh, pointerDown, pointerMove, pointerUp, undo, keyboard, setActive,
    isEditing: () => Boolean(drag || textEdit), isDragging: () => Boolean(drag), isActive: () => mode };
}

if (typeof module !== "undefined") module.exports = { WallMemoryModel, createWallMemoryEditor };
