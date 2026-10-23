/** Exercise production map loading, spawning and skin selection against installed sprites. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const root = path.resolve(__dirname, "../../RandomForest");
const sprites = new Set(fs.readdirSync(path.join(root, "sprites")));
const kinds = {oBarkGuard: "guard", oResinSlime: "slime", oBarkBomber: "barrel",
  oForestBat: "bat", oRootReaper: "sweeper", oRootMaw: "maw"};
const objects = ["oPlayer", "oDoor", "oCoin", "oSlime", "oSkeleton", "oBungalo", "oPointer", ...Object.keys(kinds)];
let skinRolls = 0;
const context = vm.createContext({
  global: {playing_level: 0}, self: {}, room: "generated", rGeneratedLevel: "generated",
  noone: -1, c_white: 255, sign: Math.sign, floor: Math.floor,
  irandom: () => skinRolls++ % 2,
  funGetRoomIndex: () => -1,
  variable_instance_exists: (instance, name) => Object.hasOwn(instance, name),
  variable_global_exists: name => Object.hasOwn(context.global, name),
  variable_struct_exists: (value, name) => Object.hasOwn(value, name),
  variable_struct_get: (value, name) => value[name],
  variable_struct_set: (value, name, item) => { value[name] = item; },
  array_create: (length, value) => Array(length).fill(value), array_length: value => value.length,
  string_repeat: (value, count) => value.repeat(count), string_length: value => value.length,
  string_char_at: (value, index) => value.charAt(index - 1),
  string_pos: (needle, value) => value.indexOf(needle) + 1,
  string_delete: (value, index, count) => value.slice(0, index - 1) + value.slice(index - 1 + count),
  string_insert: (item, value, index) => value.slice(0, index - 1) + item + value.slice(index - 1),
  show_error: message => { throw new Error(message); },
  asset_get_index: name => sprites.has(name) ? name : -1, sprite_get_name: name => name,
  funEnemyInitializeMovement: mask => { context.self.mask_index = mask; },
  funForestBatFindCeiling() {}, funForestEnemyCreateGlow() {},
  funForestEnemyPose: () => ({x: 0, y: 0}),
  draw_sprite_ext: (...args) => context.draws.push(args),
  ...Object.fromEntries([...sprites, ...objects].map(name => [name, name])),
  instance_create_layer(x, y, layer, object, values) {
    context.self = {x, y, image_alpha: 1, ...values};
    context.funForestEnemyInitialize(kinds[object]);
    return context.self;
  }
});

// Translate only GML syntax; the functions under test remain the production source.
function run(source) {
  vm.runInContext(source.replace(/\band\b/g, "&&").replace(/\bor\b/g, "||")
    .replace(/\bmod\b/g, "%").replace(/\[@\s*/g, "["), context);
}

for (const name of ["scriptLevelThemes", "scriptRootMawSkins", "scriptForestEnemyCore", "funDecodeGeneratedLevelMap"]) {
  run(fs.readFileSync(path.join(root, "scripts", name, name + ".gml"), "utf8"));
}
const builder = fs.readFileSync(path.join(root, "scripts/funBuildGeneratedLevel/funBuildGeneratedLevel.gml"), "utf8");
run(builder.slice(builder.indexOf("function __funGeneratedEntityObject("),
  builder.indexOf("function __funBuildGeneratedEntities(")));

const symbols = "GgJjCcTtWwFf";
const prefixes = {G: "sBarkGuard", J: "sResinSlime", C: "sBarkBomber",
  T: "sForestBat", W: "sRootReaper", F: "sRootMaw"};
for (const [index, suffix] of [[10, ""], [21, "Evening"], [31, "Night"], [40, "Morning"]]) {
  context.global.playing_level = index;
  const level = context.funDecodeGeneratedLevelMap({width: symbols.length, height: 3,
    map: [".".repeat(symbols.length), symbols, "#".repeat(symbols.length)]});
  for (let column = 0; column < symbols.length; column++) {
    const symbol = symbols[column], upper = symbol.toUpperCase();
    const row = upper === "T" ? 1 : 2;
    assert.equal(level.entities[row][column], symbol);
    context.__funBuildGeneratedEntity(symbol, column, row);
    const actor = context.self;
    assert.equal(actor.x, column * 12);
    assert.equal(actor.y, row * 12);
    assert.equal(Math.sign(actor.image_xscale), symbol === upper ? 1 : -1);
    const scale = "GW".includes(upper) ? 1.5 : 1;
    assert.equal(Math.abs(actor.image_xscale), scale);
    assert.equal(actor.image_yscale, scale);
    assert.notEqual(actor.mask_index, -1);

    // Cover every native pose, including fallback when only evening/night art exists.
    const prefix = prefixes[upper];
    const poses = [...sprites].filter(name => name.startsWith(prefix) &&
      !/(Evening|Night|Morning|Collision|Bloom|Bare|Cast|Thorn|Rosette|N1|N5)$/.test(name));
    assert(poses.length > 0);
    for (const base of poses) {
      actor.sprite_index = base;
      actor.image_index = 1;
      context.draws = [];
      context.funForestEnemyDraw();
      let expected = sprites.has(base + suffix) ? base + suffix : base;
      if (base === "sBarkBomberAttack") expected = "sBarkBomberAttackCast";
      if (upper === "F") expected = context.funRootMawSkinSprite(base + "Bare", actor.maw_skin);
      assert(sprites.has(expected), expected);
      assert.equal(context.draws[0][0], expected, `${symbol} / ${suffix || "day"} / ${base}`);
      assert.equal(context.draws[0][1], 1);
      assert.equal(actor.sprite_index, base);
      assert.equal(actor.mask_index, prefix + "Collision");
      if (upper === "F") assert.equal(context.draws[1][0], context.funRootMawSkinSprite("sRootMawRosette", actor.maw_skin));
    }
  }
}
// A level has one choice for every plant and retry; entering another level makes one new draw.
const first = context.funRootMawStartLevel(31), rolls = skinRolls;
for (let retry = 0; retry < 10; retry++) assert.equal(context.funRootMawStartLevel(31), first);
assert.equal(skinRolls, rolls, "room restarts must not reroll the appearance");
const second = context.funRootMawStartLevel(32);
assert.notEqual(first, second, "both approved skins can be selected");
assert.equal(skinRolls, rolls + 1);
for (const skin of ["N1", "N5"]) {
  for (const pose of ["Idle", "Prepare", "Attack", "Recover", "Hurt", "Die"]) {
    assert(sprites.has(context.funRootMawSkinSprite("sRootMaw" + pose + "Bare", skin)));
    if (pose !== "Die") assert(sprites.has(context.funRootMawSkinSprite("sRootMaw" + pose + "Bloom", skin)));
  }
}
for (const symbol of "1234567") {
  assert.throws(() => context.funDecodeGeneratedLevelMap({width: 1, height: 2, map: [symbol, "#"]}),
    /unsupported symbol/);
  assert.equal(context.__funGeneratedEntityObject(symbol), -1);
}
console.log("PASS: enemy maps, anchors, scales, all poses, two matching plant skins and one selection per level across retries");
