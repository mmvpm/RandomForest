"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const source = fs.readFileSync(path.join(__dirname,
  "../../RandomForest/scripts/scriptWallMemoryStorage/scriptWallMemoryStorage.gml"), "utf8");
let values = {}, fileLines = [], cursor = 0;
const context = vm.createContext({
  global: {wall_memory_read: {}},
  json_parse: JSON.parse, json_stringify: JSON.stringify,
  is_struct: value => value !== null && typeof value === "object" && !Array.isArray(value),
  base64_encode: text => Buffer.from(text, "utf8").toString("base64"),
  base64_decode: text => Buffer.from(text, "base64").toString("utf8"),
  ini_key_exists: (section,key) => Object.hasOwn(values, key),
  // GameMaker terminates an INI string at the first embedded quotation mark.
  ini_read_string: (section,key,fallback) => Object.hasOwn(values,key)
    ? values[key].split('"')[0] : fallback,
  ini_write_string: (section,key,value) => { values[key] = value; },
  ini_key_delete: (section,key) => { delete values[key]; },
  file_exists: () => fileLines.length > 0,
  file_text_open_read: () => { cursor = 0; return 1; },
  file_text_eof: () => cursor >= fileLines.length,
  file_text_read_string: () => fileLines[cursor], file_text_readln: () => { cursor++; },
  file_text_close() {}, string_trim: text => text.trim(),
  string_char_at: (text,index) => text[index-1] || "",
  string_length: text => text.length, string_pos: (needle,text) => text.indexOf(needle)+1,
  string_copy: (text,start,count) => text.slice(start-1,start-1+count),
  string_delete: (text,start,count) => text.slice(0,start-1)+text.slice(start-1+count)
});
vm.runInContext(source.replace(/\band\b/g,"&&").replace(/\bor\b/g,"||"), context);
const plain = result => JSON.parse(JSON.stringify(result));
assert.deepEqual(plain(context.funLoadWallMemoryReadState()), {});
const readState = {"12:route_memory_1":true,"21:previous_memory":true,'42:future_"якорь"':true};
const json = JSON.stringify(readState);
values = {read:json};
fileLines = ['[general]', 'current_level="21"', '[wall_memories]', `read="${json}"`,
  '[black_room_seen]', 'first="1"'];
assert.equal(context.ini_read_string("wall_memories","read","{}"), "{");
assert.deepEqual(plain(context.funLoadWallMemoryReadState()), readState);
context.global.wall_memory_read = readState;
context.funSaveWallMemoryReadState();
assert(!Object.hasOwn(values,"read"));
assert(!values.read_base64.includes('"'));
assert.deepEqual(plain(context.funLoadWallMemoryReadState()), readState);
context.global.wall_memory_read = {};
context.funSaveWallMemoryReadState();
assert.deepEqual(plain(context.funLoadWallMemoryReadState()), {});
// A corrupt new record must not resurrect the legacy flags after a reset.
for (const text of ["", "!!!", Buffer.from("{").toString("base64"),
    Buffer.from("null").toString("base64"), Buffer.from("[]").toString("base64")]) {
  values.read_base64 = text;
  assert.deepEqual(plain(context.funLoadWallMemoryReadState()), {});
}
values = {read:"{"}; fileLines = ['[wall_memories]', 'read="{"'];
assert.deepEqual(plain(context.funLoadWallMemoryReadState()), {});
console.log("Actual storage GML: legacy quote recovery, Base64 round trip, arbitrary keys, reset, corrupt/empty records and absent saves passed.");
