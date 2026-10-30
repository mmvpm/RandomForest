/** Core transparency must not dim the independently adjustable particle halos. */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = fs.readFileSync(path.resolve(__dirname,
  '../../RandomForest/scripts/scriptMemoryAbsorption/scriptMemoryAbsorption.gml'), 'utf8');

/** Execute the production draw routine with a chosen set of artist controls. */
function render(coreAlpha, glowAlpha, glowScale, age=10) {
  let alpha = .5, mode = 'normal';
  const halos = [], cores = [];
  const context = vm.createContext({
    self:{memory_particles:[{x:20,y:30,age,vx:0,vy:0,glow_stretch:1,glow_angle:0,glow_weight:1}]},
    min:Math.min, round:Math.round,
    bm_add:'add', bm_normal:'normal', sCoinBloom:1, c_white:0xffffff,
    ORANGE_FIREFLY_COLOUR:2, ORANGE_FIREFLY_GLOW_COLOUR:3,
    array_length:a=>a.length, draw_set_color(){},
    draw_set_alpha:value=>{alpha=value;}, gpu_set_blendmode:value=>{mode=value;},
    draw_sprite_ext:(...args)=>halos.push({args,alpha,mode}),
    draw_rectangle:(...args)=>cores.push({args,alpha,mode}),
  });
  const code = source.replace(/^#macro MEMORY_PARTICLE_ALPHA .+$/m,`#macro MEMORY_PARTICLE_ALPHA ${coreAlpha}`)
    .replace(/^#macro MEMORY_PARTICLE_GLOW_ALPHA .+$/m,`#macro MEMORY_PARTICLE_GLOW_ALPHA ${glowAlpha}`)
    .replace(/^#macro MEMORY_PARTICLE_GLOW_SCALE .+$/m,`#macro MEMORY_PARTICLE_GLOW_SCALE ${glowScale}`)
    .replace(/^#macro (\w+) (.+)$/gm,'const $1 = $2;')
    .replace(/\band\b/g,'&&').replace(/\bmod\b/g,'%');
  vm.runInContext(code, context);
  context.funMemoryAbsorptionDraw();
  return {halos,cores,alpha,mode};
}
for (const coreAlpha of [0,.04,.9]) {
  const result=render(coreAlpha,.2,.65);
  assert.equal(result.cores[0].alpha,coreAlpha);
  assert.equal(result.halos[0].args[8],.2,'halo alpha is independent of the core');
  assert.equal(result.halos[0].alpha,1,'a previous core draw cannot dim the next halo');
  assert.equal(result.halos[0].args[4],.65);
  assert.equal(result.halos[0].mode,'add');
  assert.equal(result.alpha,1); assert.equal(result.mode,'normal');
}
const larger=render(.04,.7,1.2);
assert.equal(larger.halos[0].args[8],.7);
assert.equal(larger.halos[0].args[4],1.2);
assert.equal(larger.cores[0].alpha,.04);
const fading=render(.04,.2,.65,54);
assert.equal(fading.cores[0].alpha,.02);
assert.equal(fading.halos[0].args[8],.1,'lifetime fade still affects both layers');
const emerging=render(.04,.2,.65,3);
assert.equal(emerging.halos[0].args[8],.1,'cloud appears gradually');
console.log('PASS: independent core alpha, halo alpha/size, additive blending and lifetime fade');
