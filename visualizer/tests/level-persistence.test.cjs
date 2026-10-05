"use strict";
const assert = require("node:assert/strict");
const { createLevelPersistence } = require("../level-persistence.js");

// Creates a real persistence controller with a deterministic HTTP transport.
function fixture(request) {
  const state = { levelNumber: 11, editRevision: 1, loadedPath: "levels/11.json", loadedText: "original",
    level: { width: 1, height: 1, map: ["X"], wall_memories: [{ id: "memory_1", x: 30 }] },
    undoStack: [{ kind: "wall_memories" }] };
  const statuses = [];
  const persistence = createLevelPersistence({ state, request,
    getPath: n => `levels/${n}.json`, getSaveUrl: n => `api/levels/${n}.json`, statusUrl: "api/status",
    setStatus: (...args) => statuses.push(args), onChange() {} });
  return { state, persistence, statuses };
}

// Lets a request remain in flight while newer revisions or level changes occur.
function deferred() {
  let resolve;
  const promise = new Promise(done => { resolve = done; });
  return { promise, resolve };
}

// Exercises failure recovery, ordered revisions and drafts across level changes.
async function main() {
  let online = false;
  const writes = [];
  const f = fixture(async (url, options) => {
    if (!online) throw new TypeError("Failed to fetch");
    if (url === "api/status") return { ok: true, json: async () => ({ can_save: true }) };
    writes.push(options.body);
    return { ok: true };
  });
  const { state, persistence: p, statuses } = f;
  assert.equal(await p.checkConnection(), false);
  assert.match(statuses.at(-1)[1], /python3 visualizer\/server.py/);
  await p.save();
  assert(p.hasUnsaved());
  assert.equal(state.loadedText, "original");
  assert.equal(p.getDraft(11).level, state.level);
  assert.equal(p.getDraft(11).undoStack, state.undoStack);
  for (let i = 0; i < 4; i++) assert(p.reportStatus());
  assert.equal(state.level.wall_memories[0].x, 30);
  state.level.wall_memories[0].x = 50; state.editRevision++;
  await p.save();
  online = true;
  await p.retry();
  assert(!p.hasUnsaved());
  assert.equal(JSON.parse(writes.at(-1)).wall_memories[0].x, 50);
  assert.equal(state.loadedText, writes.at(-1));
  assert.equal(state.undoStack.length, 1);

  const gate = deferred();
  let count = 0;
  const ordered = fixture(async () => ++count === 1 ? gate.promise : { ok: false, status: 500 });
  const first = ordered.persistence.save();
  await new Promise(resolve => setImmediate(resolve));
  ordered.state.level.wall_memories[0].x = 80; ordered.state.editRevision++;
  const second = ordered.persistence.save();
  gate.resolve({ ok: true });
  await first;
  assert(ordered.persistence.hasUnsaved());
  assert.equal(JSON.parse(ordered.state.loadedText).wall_memories[0].x, 30);
  await second;
  assert(ordered.persistence.hasUnsaved());
  assert.equal(ordered.state.level.wall_memories[0].x, 80);
  assert.match(ordered.statuses.at(-1)[1], /HTTP 500/);

  const moved = fixture(async () => { throw new TypeError("Failed to fetch"); });
  await moved.persistence.save();
  const draft = moved.persistence.getDraft(11);
  moved.state.levelNumber = 12; moved.state.level = { map: ["."] }; moved.state.undoStack = [];
  assert(!moved.persistence.hasUnsaved());
  moved.state.levelNumber = 11;
  moved.state.level = draft.level; moved.state.undoStack = draft.undoStack;
  assert(moved.persistence.hasUnsaved());
  assert.equal(moved.state.level.wall_memories[0].x, 30);
  assert.equal(moved.state.undoStack.length, 1);

  const health = deferred(); let puts = 0;
  const switching = fixture(async (url) => {
    if (url === "api/status") return health.promise;
    puts++; throw new TypeError("Failed to fetch");
  });
  await switching.persistence.save();
  const retry = switching.persistence.retry();
  switching.state.levelNumber = 12;
  health.resolve({ ok: true, json: async () => ({ can_save: true }) });
  await retry;
  assert.equal(puts, 1); // A delayed health response must not save another level.
  assert(switching.persistence.hasUnsaved(11));
  console.log("Persistence: network/HTTP failure, latest retry, ordered saves, draft navigation and delayed retry passed.");
}

main().catch(error => { console.error(error); process.exitCode = 1; });
