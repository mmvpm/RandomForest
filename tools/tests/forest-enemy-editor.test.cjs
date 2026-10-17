/** Verify independent map symbols, facing rotation, skin presets and scoped editor drawing. */
const assert=require('node:assert/strict');const api=require('../../visualizer/forest-enemies.js');
const commands=[];const ctx={save(){commands.push('save');},restore(){commands.push('restore');},fillRect(){commands.push('rect');},fillText(s){commands.push(s);}};
assert.equal(api.items.length,13);assert.equal(api.rotated.F,'f');assert.equal(api.rotated.f,'F');assert.equal(api.rotated.T,'t');
for(const symbol of 'FfJjCcTtGgWw1234567'){assert(api.names[symbol],symbol);assert(api.draw(ctx,symbol,0,0));}
assert.equal(api.draw(ctx,'R',0,0),false);assert.equal(commands.filter(c=>c==='save').length,commands.filter(c=>c==='restore').length);
assert.equal(new Set(api.items.flatMap(i=>[...i.symbols])).size,19);console.log('PASS: six enemy tools, seven theme presets, facing and scoped drawing');
