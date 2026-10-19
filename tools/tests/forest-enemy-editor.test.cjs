/** Verify family tools and cell-local mini icons, including distant cells and mirroring. */
"use strict";
const assert = require("node:assert/strict");
const api = require("../../visualizer/forest-enemies.js");

// Records filled geometry after the same translate/scale operations used by Canvas.
function recordingContext() {
  let state = {x: 0, y: 0, sx: 1, sy: 1, fillStyle: "initial"};
  let path = [];
  const stack = [], shapes = [];
  const point = (x, y) => [state.x + x * state.sx, state.y + y * state.sy];
  return {
    shapes,
    get fillStyle() { return state.fillStyle; },
    set fillStyle(value) { state.fillStyle = value; },
    save() { stack.push({...state}); },
    restore() { assert(stack.length > 0); state = stack.pop(); },
    translate(x, y) { state.x += x * state.sx; state.y += y * state.sy; },
    scale(x, y) { state.sx *= x; state.sy *= y; },
    beginPath() { path = []; },
    moveTo(x, y) { path.push(point(x, y)); },
    lineTo(x, y) { path.push(point(x, y)); },
    closePath() {},
    fill() { shapes.push({color: state.fillStyle, points: [...path]}); },
    fillRect(x, y, width, height) {
      shapes.push({color: state.fillStyle,
        points: [point(x, y), point(x + width, y), point(x + width, y + height), point(x, y + height)]});
    },
    fillText() { assert.fail("Enemy mini icons must not render letter markers"); },
    assertRestored() {
      assert.equal(stack.length, 0);
      assert.deepEqual(state, {x: 0, y: 0, sx: 1, sy: 1, fillStyle: "initial"});
    }
  };
}

assert.equal(api.items.length, 6);
const silhouettes = new Set();
for (const upper of "FJCTGW") {
  const lower = upper.toLowerCase();
  assert.equal(api.rotated[upper], lower);
  assert.equal(api.rotated[lower], upper);
  assert.equal(api.items.filter(item => item.symbols.includes(upper)).length, 1);
  assert(api.names[upper]); assert(api.names[lower]);
  const origin = recordingContext();
  assert(api.draw(origin, upper, 0, 0));
  silhouettes.add(JSON.stringify(origin.shapes.map(shape => shape.points)));
  origin.assertRestored();

  for (const [column, row, size] of [[0, 0, 16], [91, 38, 16], [7, 13, 32]]) {
    for (const symbol of [upper, lower]) {
      const context = recordingContext();
      assert(api.draw(context, symbol, column, row, size));
      assert(context.shapes.length >= 3, "Draw a silhouette and details");
      const expected = origin.shapes.map(shape => ({color: shape.color,
        points: shape.points.map(([x, y]) => [
          column * size + (symbol === upper ? x : 16 - x) * size / 16,
          row * size + y * size / 16
        ])}));
      assert.deepEqual(context.shapes, expected, `${symbol} in cell (${column}, ${row})`);
      for (const {points} of context.shapes) {
        for (const [x, y] of points) {
          assert(x > column * size && x < (column + 1) * size);
          assert(y > row * size && y < (row + 1) * size);
        }
      }
      context.assertRestored();
    }
  }
}
assert.equal(silhouettes.size, 6, "Each family needs a distinct silhouette");
assert.equal(new Set(api.items.flatMap(item => [...item.symbols])).size, 12);
for (const symbol of "1234567R.") {
  const context = recordingContext();
  assert.equal(api.names[symbol], undefined);
  assert.equal(api.draw(context, symbol, 91, 38), false);
  assert.equal(context.shapes.length, 0);
  context.assertRestored();
}
console.log("PASS: six distinct enemy icons, correct cell placement, mirrored facing, scaling and canvas state");
