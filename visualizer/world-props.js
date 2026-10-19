"use strict";

// Keeps group transforms and visual defaults independent of the map symbols.
const WorldPropModel = {
  // Keeps older authored props fully visible without rewriting their JSON.
  opacity(prop) { return prop.opacity ?? 100; },
  // Keeps older authored props in their original position above platforms.
  platformLayer(prop) { return prop.platform_layer ?? "above"; },
  // Includes both collision types when bounding or moving the complete group.
  collisionCells(prop) { return prop.solids.concat(prop.jump_thrus ?? []); },
  // Converts one stored cell to the reflected world collision grid.
  worldCell(prop, cell) {
    return [prop.x / 6 + (prop.mirrored ? -cell[0] - 1 : cell[0]), prop.y / 6 + cell[1]];
  },
  // Converts a world-pixel pointer to an unreflected local cell.
  localCell(prop, point) {
    const column = Math.floor((point.x - prop.x) / 6);
    return [prop.mirrored ? -column - 1 : column, Math.floor((point.y - prop.y) / 6)];
  },
  // Matches the native sprite origin for normal and mirrored drawings.
  bounds(prop, definition) {
    return { left: prop.x + (prop.mirrored ? definition.origin[0] - definition.width : -definition.origin[0]),
      top: prop.y - definition.origin[1], width: definition.width, height: definition.height };
  },
  // Allows clipped artwork but keeps the anchor and every physical cell in the room.
  fits(prop, width, height) {
    return prop.x >= 0 && prop.y >= 0 && prop.x <= width * 12 && prop.y <= height * 12 &&
      this.collisionCells(prop).every(cell => {
        const [x, y] = this.worldCell(prop, cell);
        return x >= 0 && y >= 0 && x < width * 2 && y < height * 2;
      });
  },
  // Clamps a proposed snapped position using the complete group's collision bounds.
  move(prop, x, y, width, height) {
    let minX = 0, minY = 0, maxX = width * 12, maxY = height * 12;
    for (const cell of this.collisionCells(prop)) {
      const column = prop.mirrored ? -cell[0] - 1 : cell[0];
      minX = Math.max(minX, -column * 6); maxX = Math.min(maxX, width * 12 - (column + 1) * 6);
      minY = Math.max(minY, -cell[1] * 6); maxY = Math.min(maxY, height * 12 - (cell[1] + 1) * 6);
    }
    return { x: Math.max(minX, Math.min(maxX, Math.round(x / 6) * 6)),
      y: Math.max(minY, Math.min(maxY, Math.round(y / 6) * 6)) };
  },
  // Uses the same campaign lighting ranges as the runtime.
  theme(number) {
    const index = number + 9;
    return index < 20 ? "day" : index < 30 ? "evening" : index < 40 ? "night" : "morning";
  }
};

// Keeps prop authoring independent of terrain painting, inscriptions and the save queue.
function createWorldPropEditor({ state, canvas, render, save, hideTooltip }) {
  const panel = document.getElementById("world-prop-panel");
  const controls = Object.fromEntries([...panel.querySelectorAll("[data-prop]")]
    .map(element => [element.dataset.prop, element]));
  let active = false, selected = null, tool = "move", chosen = null, gesture = null, hover = null;
  let definitions = [], message = "Загрузка предметов…";
  const images = new Map();
  const thumbnails = new Map();
  let instanceSignature = "";

  // Returns the selected group by stable ID rather than a changing array index.
  function item() { return state.level?.props?.find(prop => prop.id === selected); }
  // Resolves the common catalogue entry used for bounds and drawing.
  function definition(prop) { return definitions.find(entry => entry.slug === prop.type); }
  // Captures the exact optional array so undo also restores legacy field absence.
  function snapshot() {
    return { kind: "props", value: state.level.props === undefined ? undefined : structuredClone(state.level.props) };
  }
  // Commits exactly one complete gesture through the shared persistence queue.
  function commit(before) {
    if (JSON.stringify(before.value) === JSON.stringify(state.level.props)) return;
    state.undoStack.push(before); state.editRevision++; render(); refresh(); save();
  }
  // Converts display coordinates into native world pixels independently of zoom.
  function point(event) {
    const bounds = canvas.getBoundingClientRect();
    return { x: (event.clientX - bounds.left) / bounds.width * state.level.width * 12,
      y: (event.clientY - bounds.top) / bounds.height * state.level.height * 12 };
  }
  // Allocates an ID without using gameplay randomness or touching other groups.
  function nextId() {
    let number = 1;
    while (state.level.props?.some(prop => prop.id === `prop_${number}`)) number++;
    return `prop_${number}`;
  }
  // Chooses overlapping art in drawing order; the instance list can select hidden groups.
  function hit(position) {
    for (const layer of ["above", "below"]) {
      const found = [...(state.level.props || [])].reverse().find(prop => {
        if (WorldPropModel.platformLayer(prop) !== layer) return false;
        const entry = definition(prop); if (!entry) return false;
        const box = WorldPropModel.bounds(prop, entry);
        return position.x >= box.left && position.y >= box.top &&
          position.x < box.left + box.width && position.y < box.top + box.height;
      });
      if (found) return found;
    }
  }
  // Loads each exact PNG at most once; failed art does not disable map editing.
  function imageFor(entry, theme) {
    const path = entry.variants[theme].image;
    if (!images.has(path)) {
      const image = new Image();
      image.onload = () => render();
      image.onerror = () => { message = `Не удалось загрузить рисунок: ${entry.name}`; refresh(); };
      images.set(path, image); image.src = "../RandomForest/" + path;
    }
    return images.get(path);
  }
  // Previews the same fixed lantern source and fading beam as the runtime.
  function drawLight(context, entry) {
    if (!entry.light) return;
    const light = entry.light, theme = WorldPropModel.theme(state.levelNumber);
    const strength = theme === "night" ? 1 : theme === "evening" ? 0.65 : 0.25;
    const beam = context.createLinearGradient(light.x, light.y, light.x + light.dx, light.y + light.dy);
    beam.addColorStop(0, `rgba(224,210,247,${0.17 * strength})`);
    beam.addColorStop(1, "rgba(224,210,247,0)");
    context.fillStyle = beam; context.beginPath();
    context.moveTo(light.x, light.y - 3); context.lineTo(light.x, light.y + 3);
    context.lineTo(light.x + light.dx, light.y + light.dy + light.half_width);
    context.lineTo(light.x + light.dx, light.y + light.dy - light.half_width);
    context.closePath(); context.fill();
    const halo = context.createRadialGradient(light.x, light.y, 0, light.x, light.y, 40);
    halo.addColorStop(0, `rgba(224,210,247,${0.3 * strength})`);
    halo.addColorStop(1, "rgba(224,210,247,0)");
    context.fillStyle = halo; context.fillRect(light.x - 40, light.y - 40, 80, 80);
  }
  // Places the small glass glow above the opaque lantern art.
  function drawLightSource(context, entry) {
    if (!entry.light) return;
    const light = entry.light, x = light.x - 7, y = light.y;
    const theme = WorldPropModel.theme(state.levelNumber);
    const strength = theme === "night" ? 1 : theme === "evening" ? 0.65 : 0.25;
    const halo = context.createRadialGradient(x, y, 0, x, y, 14);
    halo.addColorStop(0, `rgba(238,222,255,${0.58 * strength})`);
    halo.addColorStop(1, "rgba(238,222,255,0)");
    context.fillStyle = halo; context.fillRect(x - 14, y - 14, 28, 28);
  }
  // Draws native pixels using exactly the same origin and reflection as GameMaker.
  function drawSprite(context, prop, alpha = 1) {
    const entry = definition(prop); if (!entry) return;
    const image = imageFor(entry, WorldPropModel.theme(state.levelNumber));
    if (!image.complete || !image.naturalWidth) return;
    context.save(); context.globalAlpha = alpha * WorldPropModel.opacity(prop) / 100; context.imageSmoothingEnabled = false;
    context.translate(prop.x, prop.y); context.scale(prop.mirrored ? -1 : 1, 1);
    drawLight(context, entry);
    context.drawImage(image, -entry.origin[0], -entry.origin[1]);
    drawLightSource(context, entry); context.restore();
  }
  // Draws one side of the platform layer, keeping hazards and characters in front.
  function drawArt(context, platformLayer = "above") {
    if (!state.level || !controls.visible.checked) return;
    for (const prop of state.level.props || []) {
      if (WorldPropModel.platformLayer(prop) === platformLayer) drawSprite(context, prop);
    }
    if (platformLayer === "above" && active && tool === "place" && chosen && hover && !gesture) {
      drawSprite(context, { type: chosen, x: Math.round(hover.x / 6) * 6,
        y: Math.round(hover.y / 6) * 6, mirrored: false }, 0.5);
    }
  }
  // Shows ownership without drawing platform tiles or changing the underlying map.
  function drawOverlay(context) {
    if (!state.level) return;
    context.save();
    if (controls.collisions.checked || (active && tool === "solids")) {
      for (const prop of state.level.props || []) {
        const own = active && prop.id === selected;
        drawCells(context, prop, "solids", own);
        drawCells(context, prop, "jump_thrus", own);
      }
    }
    const prop = item(), entry = prop && definition(prop);
    if (active && entry) {
      const box = WorldPropModel.bounds(prop, entry);
      context.strokeStyle = "#ffc84b"; context.lineWidth = 1;
      context.strokeRect(box.left, box.top, box.width, box.height);
      context.fillStyle = "#ffc84b"; context.fillRect(prop.x - 2, prop.y - 2, 4, 4);
      if (tool === "solids") drawGrid(context, box);
    }
    context.restore();
  }
  // Distinguishes solid squares from one-way top edges while retaining owner colours.
  function drawCells(context, prop, kind, own) {
    context.fillStyle = own ? "rgba(255,200,75,.45)" : "rgba(75,210,230,.25)";
    context.strokeStyle = own ? "#ffc84b" : "#4bd2e6";
    for (const cell of prop[kind] || []) {
      const [x, y] = WorldPropModel.worldCell(prop, cell);
      if (kind === "solids") {
        context.lineWidth = 0.5;
        context.fillRect(x * 6, y * 6, 6, 6); context.strokeRect(x * 6, y * 6, 6, 6);
      } else {
        context.lineWidth = 2; context.beginPath();
        context.moveTo(x * 6, y * 6 + 1); context.lineTo(x * 6 + 6, y * 6 + 1); context.stroke();
      }
    }
  }
  // Adds a local six-pixel guide only around the selected artwork and hovered cell.
  function drawGrid(context, box) {
    const left = Math.max(0, Math.floor(box.left / 6) * 6), top = Math.max(0, Math.floor(box.top / 6) * 6);
    const right = Math.min(state.level.width * 12, box.left + box.width + 6);
    const bottom = Math.min(state.level.height * 12, box.top + box.height + 6);
    context.strokeStyle = "rgba(255,200,75,.18)"; context.lineWidth = 0.5; context.beginPath();
    for (let x = left; x <= right; x += 6) { context.moveTo(x, top); context.lineTo(x, bottom); }
    for (let y = top; y <= bottom; y += 6) { context.moveTo(left, y); context.lineTo(right, y); }
    context.stroke();
    if (hover) { context.strokeStyle = "#fff1b5";
      context.strokeRect(Math.floor(hover.x / 6) * 6, Math.floor(hover.y / 6) * 6, 6, 6); }
  }
  // Refreshes selection and lightweight controls without rebuilding the palette on every drag.
  function refresh(reset = false) {
    if (reset) { selected = null; gesture = null; hover = null; tool = "move"; }
    const prop = item();
    if (!prop) selected = null;
    controls.position.textContent = prop ? `${definition(prop)?.name || prop.type} · ${prop.x}, ${prop.y} px · Solid: ${prop.solids.length}, Jump-through: ${prop.jump_thrus?.length || 0}` : "Предмет не выбран";
    for (const name of ["solids", "duplicate", "mirror", "delete", "opacity", "platform_layer", "collision_type"]) controls[name].disabled = !prop;
    controls.opacity.value = String(prop ? WorldPropModel.opacity(prop) : 100);
    controls.platform_layer.value = prop ? WorldPropModel.platformLayer(prop) : "above";
    controls.move.setAttribute("aria-pressed", String(tool === "move"));
    controls.solids.setAttribute("aria-pressed", String(tool === "solids"));
    for (const [slug, button] of thumbnails) button.setAttribute("aria-pressed", String(tool === "place" && chosen === slug));
    controls.message.textContent = tool === "place" ? `Размещение: ${definitions.find(entry => entry.slug === chosen)?.name}. Кликните на карте; Esc — отмена.` : message;
    const signature = JSON.stringify([selected, (state.level?.props || []).map(group => [group.id, group.type])]);
    if (signature === instanceSignature) return;
    instanceSignature = signature;
    controls.instances.replaceChildren();
    for (const group of state.level?.props || []) {
      const button = document.createElement("button"); button.type = "button"; button.className = "prop-instance";
      button.textContent = `${definition(group)?.name || group.type} · ${group.id}`;
      button.setAttribute("aria-pressed", String(group.id === selected));
      button.addEventListener("click", () => { pointerUp(); selected = group.id; tool = "move"; refresh(); render(); });
      controls.instances.appendChild(button);
    }
  }
  // Selects an explicit tool so placing cannot accidentally erase or duplicate existing groups.
  function setTool(value) { pointerUp(); tool = value; refresh(); render(); }
  // Paints one collision type, replacing the other type only in the selected group.
  function paint(position) {
    const prop = item(), cell = WorldPropModel.localCell(prop, position), key = cell.join(":");
    if (gesture.visited.has(key)) return;
    gesture.visited.add(key);
    const cells = prop[gesture.kind] || [];
    const index = cells.findIndex(candidate => candidate[0] === cell[0] && candidate[1] === cell[1]);
    if (gesture.erase && index !== -1) cells.splice(index, 1);
    else if (!gesture.erase && index === -1) {
      const [x, y] = WorldPropModel.worldCell(prop, cell);
      if (x < 0 || y < 0 || x >= state.level.width * 2 || y >= state.level.height * 2) return;
      if (!prop[gesture.kind]) prop[gesture.kind] = cells;
      cells.push(cell);
      const otherKind = gesture.kind === "solids" ? "jump_thrus" : "solids";
      const otherCells = prop[otherKind];
      const otherIndex = otherCells?.findIndex(candidate => candidate[0] === cell[0] && candidate[1] === cell[1]) ?? -1;
      if (otherIndex !== -1) otherCells.splice(otherIndex, 1);
    }
  }
  // Fills small cells between pointer events so a fast brush cannot leave holes.
  function paintLine(position) {
    const previous = gesture.previous || position;
    const steps = Math.max(1, Math.ceil(Math.max(Math.abs(position.x - previous.x), Math.abs(position.y - previous.y)) / 3));
    for (let step = 1; step <= steps; step++) paint({ x: previous.x + (position.x - previous.x) * step / steps,
      y: previous.y + (position.y - previous.y) * step / steps });
    gesture.previous = position;
    render();
  }
  // Starts placement, dragging or a collision stroke while retaining one undo snapshot.
  function pointerDown(event) {
    if (!active) return false;
    if (!state.level || (event.button !== 0 && !(tool === "solids" && event.button === 2))) return true;
    canvas.focus({ preventScroll: true }); hideTooltip();
    const position = point(event), before = snapshot();
    if (tool === "solids" && item()) {
      const kind = controls.collision_type.value === "jump_thrus" ? "jump_thrus" : "solids";
      gesture = { before, kind, erase: event.button === 2, visited: new Set(), previous: position }; paint(position);
    } else if (tool === "place" && chosen) {
      const group = { id: nextId(), type: chosen, ...WorldPropModel.move({ solids: [] }, position.x,
        position.y, state.level.width, state.level.height), mirrored: false, solids: [], opacity: 100, platform_layer: "above" };
      if (!state.level.props) state.level.props = [];
      state.level.props.push(group); selected = group.id;
      gesture = { before, offsetX: position.x - group.x, offsetY: position.y - group.y };
    } else {
      const group = hit(position); selected = group?.id || null;
      if (group) gesture = { before, offsetX: position.x - group.x, offsetY: position.y - group.y };
    }
    if (gesture) canvas.setPointerCapture(event.pointerId);
    refresh(); render(); event.preventDefault(); return true;
  }
  // Moves the entire group or extends its collision stroke without intermediate saves.
  function pointerMove(event) {
    if (!active) return false;
    if (!state.level) return true;
    hover = point(event);
    if (gesture?.visited) paintLine(hover);
    else if (gesture && item()) {
      Object.assign(item(), WorldPropModel.move(item(), hover.x - gesture.offsetX,
        hover.y - gesture.offsetY, state.level.width, state.level.height));
      refresh(); render();
    } else if (tool === "place" || tool === "solids") render();
    return true;
  }
  // Finishes a gesture once, including when switching modes or levels.
  function pointerUp() {
    if (!active) return false;
    if (gesture) {
      const before = gesture.before; gesture = null;
      if (tool === "place") tool = "move";
      commit(before); refresh(); render();
    }
    return true;
  }
  // Performs an atomic edit while retaining all unrelated level fields.
  function change(action) {
    pointerUp(); const prop = item(); if (!prop) return;
    const before = snapshot(); action(prop); commit(before); refresh(); render();
  }
  // Saves one visual setting as an undoable edit without changing collision ownership.
  function changeField(name) {
    let value = controls[name].value;
    if (name === "opacity") {
      if (value.trim() === "" || !Number.isFinite(Number(value))) { refresh(); return; }
      value = Math.max(0, Math.min(100, Math.round(Number(value))));
    } else if (value !== "above" && value !== "below") { refresh(); return; }
    change(prop => {
      const previous = name === "opacity" ? WorldPropModel.opacity(prop) : WorldPropModel.platformLayer(prop);
      if (previous !== value) prop[name] = value;
    });
  }
  // Duplicates the full group at the same position, ready for dragging to a new place.
  function duplicate() {
    change(prop => { const copy = structuredClone(prop); copy.id = nextId();
      state.level.props.push(copy); selected = copy.id; tool = "move"; });
  }
  // Reflects art and cells together, moving the anchor only if needed to stay in bounds.
  function mirror() {
    change(prop => { prop.mirrored = !prop.mirrored;
      Object.assign(prop, WorldPropModel.move(prop, prop.x, prop.y, state.level.width, state.level.height)); });
  }
  // Removes the selected group without modifying shared terrain or other prop cells.
  function remove() { change(prop => { state.level.props = state.level.props.filter(group => group.id !== prop.id);
    selected = null; tool = "move"; }); }
  // Restores a complete group edit through the existing cross-mode undo shortcut.
  function undo(edit) {
    if (edit.kind !== "props") return false;
    gesture = null;
    if (edit.value === undefined) delete state.level.props;
    else state.level.props = structuredClone(edit.value);
    state.editRevision++; refresh(); render(); save(); return true;
  }
  // Owns prop shortcuts only in prop mode; arrows retain level navigation.
  function keyboard(event) {
    if (!active) return false;
    if (event.key === "Delete" || event.key === "Backspace") remove();
    else if (event.code === "KeyR") mirror();
    else if (event.key === "Escape") setTool("move");
    else return false;
    event.preventDefault(); return true;
  }
  // Deactivates gestures before the shared editor changes its active mode.
  function setActive(value) { pointerUp(); active = value; hover = null; hideTooltip(); refresh(); render(); }
  // Loads the portable catalogue and creates the fixed nineteen-item thumbnail palette.
  async function load() {
    try {
      const response = await fetch("../RandomForest/datafiles/world_props/catalog.json", { cache: "no-store" });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      definitions = (await response.json()).props;
      for (const entry of definitions) {
        const button = document.createElement("button"); button.type = "button"; button.className = "prop-thumbnail";
        const image = document.createElement("img"); image.src = "../RandomForest/" + entry.variants.day.image; image.alt = "";
        const label = document.createElement("span"); label.textContent = entry.name;
        button.append(image, label); button.title = `${entry.width}×${entry.height} px`;
        thumbnails.set(entry.slug, button);
        button.addEventListener("click", () => { chosen = entry.slug; setTool("place"); });
        controls.palette.appendChild(button);
      }
      message = "Выберите миниатюру и поставьте предмет. Его коллизии редактируются отдельно.";
    } catch (error) { message = `Предметы недоступны: ${error.message}`; }
    refresh(); render();
  }
  controls.move.addEventListener("click", () => setTool("move"));
  controls.solids.addEventListener("click", () => setTool("solids"));
  controls.collision_type.addEventListener("change", () => setTool("solids"));
  controls.duplicate.addEventListener("click", duplicate);
  controls.mirror.addEventListener("click", mirror);
  controls.delete.addEventListener("click", remove);
  for (const name of ["opacity", "platform_layer"]) controls[name].addEventListener("change", () => changeField(name));
  for (const name of ["visible", "collisions"]) controls[name].addEventListener("change", render);
  canvas.addEventListener("contextmenu", event => { if (active && tool === "solids") event.preventDefault(); });
  canvas.addEventListener("pointerleave", () => { hover = null; if (active) render(); });
  refresh(); load();
  return { drawArt, drawOverlay, refresh, pointerDown, pointerMove, pointerUp, keyboard, undo, setActive,
    isActive: () => active, isEditing: () => Boolean(gesture) };
}

if (typeof module !== "undefined") module.exports = { WorldPropModel, createWorldPropEditor };
