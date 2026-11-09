/** Exercise native dialogue timing, sound thinning and the first finale's silent wait. */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '../../RandomForest');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const translate = source => source.replace(/^#macro (\w+) (.+)$/gm, 'const $1 = $2;')
    .replace(/\band\b/g, '&&').replace(/\bor\b/g, '||').replace(/\bexit\b/g, 'return');
let cues = [], paused = false, fade = false, shown = 0;
const c = vm.createContext({
    self: {}, global: {sfx_enabled: true, key_pause: 'escape'},
    vk_space: 'space',
    array_length: a => a.length, soundDialogueTyping: 'typing',
    audio_play_sound: (sound, priority, loop) => {
        assert.equal(sound, 'typing'); assert.equal(loop, false);
        cues.push({frame: c.self.typing_audio_frame, revealed: c.self.revealed});
    },
    oPauseMenu: {paused: false}, oPlayer: {state: 'idle'}, oFadeIn: 'fade',
    player_states: {stomp: 'stomp'}, max: Math.max,
    keyboard_check_pressed: () => paused,
    instance_exists: object => object === c.oPauseMenu || object === c.oPlayer || object === 'fade' && fade,
});
for (const name of ['scriptDialogueAudio', 'scriptDialoguePlayback'])
    vm.runInContext(translate(read(`scripts/${name}/${name}.gml`)), c);
const step = translate(read('objects/oDialogue/Step_0.gml'));

/** Begin a prepared page without replacing the production typing or cadence code. */
function begin(glyphs, speed = 30) {
    c.self = {ready: true, input_locked: false, complete_drawn: false, page_complete_drawn: false,
        pages: [{glyphs}], page_index: 0, revealed: 0, typing_frames: 0, typing_speed: speed};
    c.funResetDialogueAudio(); cues = []; paused = false; c.oPauseMenu.paused = false;
}

/** Advance the actual object Step so pause and completion guards remain in the test. */
function tick(count) {
    for (let i = 0; i < count; i++) vm.runInContext(`(function(){${step}})()`, c);
}

begin(Array.from({length: 300}, () => ({letter: 'a', delay_frames: 0})));
tick(600);
assert.equal(c.self.revealed, 300, 'text remains 30 glyphs/s');
assert.equal(cues.length, 200, '20 sounds/s does not collapse to 15 on the 30 glyph/s grid');
assert.deepEqual(cues.slice(0, 6).map(x => x.frame), [2, 6, 8, 12, 14, 18]);
assert(cues.every(x => x.frame % 2 === 0), 'every cue belongs to an actual glyph appearance');
tick(120); assert.equal(cues.length, 200, 'a completed page stays silent');

begin([{letter: 'a', delay_frames: 0}, {letter: ' ', delay_frames: 0},
    ...Array.from({length: 5}, () => ({letter: '.', delay_frames: 18}))]);
tick(94);
assert.deepEqual(cues.map(x => x.frame), [2, 22, 40, 58, 76, 94], 'spaces are silent and each slow dot has one cue');

begin(Array.from({length: 20}, () => ({letter: 'a', delay_frames: 0})));
tick(2); const clock = c.self.typing_audio_frame;
c.oPauseMenu.paused = true; tick(120);
assert.equal(c.self.typing_audio_frame, clock); assert.equal(cues.length, 1);
c.oPauseMenu.paused = false; tick(4);
assert.equal(cues.length, 2, 'resume has no catch-up burst');
c.global.sfx_enabled = false; tick(20);
assert.equal(cues.length, 2, 'the effects switch silences typing');
c.global.sfx_enabled = true; tick(4);
assert(cues.length > 2, 'typing returns at the ongoing cadence');

const config = JSON.parse(read('datafiles/narrative/black_room.json'));
const finale = config.scenes.find(s => s.kind === 'finale');
assert.equal(finale.exploration_seconds, 10);
assert.equal(config.defaults.characters_per_second, 30);
assert.equal(config.defaults.exploration_seconds, 3);
const controllerStep = translate(read('objects/oBlackRoomController/Step_0.gml'));
c.self = {is_ending: true, stage_prepared: true, ending_action: '', exiting: false,
    awaiting_transform: false, dialogue_started: false, space_guard: 0,
    delay_frames: 60 * finale.exploration_seconds, show_dialogue: () => shown++};
fade = true;
for (let i = 0; i < 60; i++) vm.runInContext(`(function(){${controllerStep}})()`, c);
assert.equal(c.self.delay_frames, 600, 'entry fade does not consume the silent wait');
fade = false;
for (let i = 0; i < 599; i++) vm.runInContext(`(function(){${controllerStep}})()`, c);
assert.equal(shown, 0);
c.oPauseMenu.paused = true;
for (let i = 0; i < 120; i++) vm.runInContext(`(function(){${controllerStep}})()`, c);
assert.equal(c.self.delay_frames, 1, 'pause does not consume the final silent frame');
c.oPauseMenu.paused = false;
vm.runInContext(`(function(){${controllerStep}})()`, c);
assert.equal(shown, 1, 'the first line appears after exactly 600 active frames');

const resource = JSON.parse(read('sounds/soundDialogueTyping/soundDialogueTyping.yy').replace(/,\s*([}\]])/g, '$1'));
assert.equal(resource.volume, 1.15, 'typing is 15% louder without changing the approved sample');
const sample = fs.readFileSync(path.join(root, 'sounds/soundDialogueTyping/soundDialogueTyping.wav'));
assert.equal(crypto.createHash('sha256').update(sample).digest('hex'),
    '423728431d75d84d355effe745caf948d49f5eccb34ab755b133c92f2d29f729', 'exact approved K10 bytes');
assert(read('datafiles/AUDIO_CREDITS.txt').includes('CodyGudmundsen'));
console.log('PASS: exact K10/+15% gain, 30 text/20 sound, slow dots, spaces, pause/mute, 600-frame first-finale wait.');
