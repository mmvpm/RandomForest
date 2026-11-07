/** Exercise authored resource gains through the real effects toggle, including a muted first launch. */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const project = path.resolve(__dirname, '../../RandomForest');
const source = fs.readFileSync(path.join(project, 'scripts/funAudioSettings/funAudioSettings.gml'), 'utf8');
const resources = fs.readdirSync(path.join(project, 'sounds')).map(name => {
    const text = fs.readFileSync(path.join(project, 'sounds', name, name + '.yy'), 'utf8');
    return {name, gain: Number(text.match(/"volume"\s*:\s*([\d.]+)/)[1])};
});

/** Run the production function against independent asset gains and track every native API call. */
function session(enabled) {
    const gains = new Map(resources.map(r => [r.name, r.gain]));
    const writes = [];
    const context = {
        global: {sfx_enabled: enabled},
        ...Object.fromEntries(resources.map(r => [r.name, r.name])),
        array_length: a => a.length,
        array_create: n => Array(n).fill(0),
        variable_global_exists: name => Object.hasOwn(context.global, name),
        audio_sound_get_gain: sound => gains.get(sound),
        audio_sound_gain(sound, gain, fade) { assert(gains.has(sound)); gains.set(sound, gain); writes.push({sound, gain, fade}); },
    };
    vm.createContext(context);
    vm.runInContext(source, context);
    return {context, gains, writes};
}

/** Require exact recovery of every authored value, rather than merely checking that sound returns. */
function assertAuthored(gains) {
    for (const resource of resources) assert.equal(gains.get(resource.name), resource.gain, resource.name);
}

for (const initiallyEnabled of [true, false]) {
    const {context, gains, writes} = session(initiallyEnabled);
    context.funApplySfxSetting();
    assert.equal(new Set(writes.map(w => w.sound)).size, resources.length, 'every sound resource belongs to the toggle');
    if (initiallyEnabled) assertAuthored(gains);
    else assert([...gains.values()].every(g => g === 0), 'first muted launch is silent');
    for (let toggle = 0; toggle < 5; toggle++) {
        context.global.sfx_enabled = false;
        context.funApplySfxSetting();
        assert([...gains.values()].every(g => g === 0));
        context.global.sfx_enabled = true;
        context.funApplySfxSetting(125);
        assertAuthored(gains);
        assert(writes.slice(-resources.length).every(w => w.fade === 125));
        context.funApplySfxSetting();
        assertAuthored(gains);
    }
}
console.log(`SFX mix passed: ${resources.length} assets; both startup states, repeated mute/unmute, no cumulative gain drift.`);
