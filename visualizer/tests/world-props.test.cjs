"use strict";
const assert = require("node:assert/strict");
const { WorldPropModel: model } = require("../world-props.js");
const prop = { x: 60, y: 48, mirrored: false, solids: [[-2, -1], [0, 0], [3, 2]] };
const definition = { width: 141, height: 241, origin: [70, 239] };
assert.deepEqual(model.bounds(prop, definition), { left: -10, top: -191, width: 141, height: 241 });
for (const mirrored of [false, true]) {
  const group = { ...prop, mirrored };
  for (const cell of group.solids) {
    const [x, y] = model.worldCell(group, cell);
    assert.deepEqual(model.localCell(group, { x: x * 6 + 3, y: y * 6 + 3 }), cell);
  }
  const position = model.move(group, -100, 1000, 10, 10);
  assert(model.fits({ ...group, ...position }, 10, 10));
  assert.equal(position.x % 6, 0); assert.equal(position.y % 6, 0);
}
assert.deepEqual(model.worldCell({ ...prop, mirrored: true }, [0, 0]), [9, 8]);
assert.deepEqual(model.worldCell({ ...prop, mirrored: true }, [-2, -1]), [11, 7]);
assert.deepEqual(model.bounds({ ...prop, mirrored: true }, definition), { left: -11, top: -191, width: 141, height: 241 });
assert(!model.fits({ ...prop, x: 0 }, 10, 10));
const jumpGroup = { ...prop, solids: [], jump_thrus: [[-11, 0], [2, -9]] };
assert(!model.fits(jumpGroup, 10, 10));
for (const mirrored of [false, true]) {
  const group = { ...jumpGroup, mirrored };
  const position = model.move(group, -100, -100, 10, 10);
  assert(model.fits({ ...group, ...position }, 10, 10));
}
assert.equal(model.collisionCells({ ...prop, jump_thrus: [[1, 1]] }).length, 4);
assert.deepEqual(model.move({ solids: [] }, 13, 17, 10, 10), { x: 12, y: 18 });
assert.deepEqual([1, 10, 11, 20, 21, 30, 31].map(model.theme), ["day", "day", "evening", "evening", "night", "night", "morning"]);
console.log("Prop transforms: native bounds, reflection, brush inverse, group clamping and campaign palettes passed.");
