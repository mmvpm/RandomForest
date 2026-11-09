/** Exercise the approved intro timing, hard stop, audio lifetime and consumed skip input. */
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '../../RandomForest');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const translate = text => text.replace(/\bstatic positions\b/g, 'var positions')
    .replace(/\band\b/g, '&&').replace(/\bor\b/g, '||').replace(/\bexit\b/g, 'return');
const cues = [], stopped = [], keys = new Set();
let clicked = false, actions = 0, audioTicks = 0;
const c = vm.createContext({self: {}, global: {sfx_enabled: true},
    min: Math.min, max: Math.max, floor: Math.floor, sin: Math.sin, pi: Math.PI,
    clamp: (value, lo, hi) => Math.max(lo, Math.min(hi, value)),
    lerp: (a, b, fraction) => a + (b - a) * fraction,
    soundStartupIntro: 'intro', vk_enter: 'enter', vk_space: 'space', vk_escape: 'escape', mb_left: 'left',
    keyboard_check_pressed: key => keys.has(key), mouse_check_button_pressed: () => clicked,
    audio_play_sound: (sound, priority, loop) => { assert.equal(sound, 'intro'); assert.equal(loop, false); cues.push(sound); audioTicks = 0; return 100 + cues.length; },
    audio_stop_sound: handle => stopped.push(handle),
    audio_is_playing: handle => !stopped.includes(handle) && audioTicks < 138,
    audio_sound_get_track_position: () => audioTicks / 60,
    instance_exists: () => false, oSettings: 'settings', oFadeOut: 'fade',
    funMenuBackgroundStep() {}, funMenuBackgroundCleanup() {}, funBrokenMenuCleanup() {},
});
for (const script of ['scriptIntroFirefly', 'scriptStartupIntro'])
    vm.runInContext(translate(read(`scripts/${script}/${script}.gml`)), c);

/** Advance the simulated mixer and execute the production Step without replacing its clock logic. */
function tickIntro() {
    audioTicks++;
    c.funStartupIntroStep();
}

// B02 moves under the title with a balanced start, then holds the same endpoint.
let previous = c.funIntroFlightProgress(0), lastSpeed = 0;
for (let frame = 1; frame <= 69; frame++) {
    const current = c.funIntroFlightProgress(frame);
    assert(current > previous && current <= 1);
    const point = f => [c.funIntroFlightSample(f, 0), c.funIntroFlightSample(f, 1)];
    const a = point(frame - 1), b = point(frame), speed = Math.hypot(b[0] - a[0], b[1] - a[1]) * 60;
    assert(b[1] >= 114 && b[1] <= 159, 'B02 passes below the title');
    assert(Math.abs(b[1] - (114 + 45 * Math.sin((b[0] - 92) / 294 * Math.PI))) < .00001);
    assert(speed >= lastSpeed - .02, 'rising speed tolerates only the arc/chord approximation');
    lastSpeed = speed; previous = current;
}
assert(lastSpeed > 480);
assert(c.funIntroFlightProgress(12) > .11, 'visible movement during the first 0.2 seconds');
assert(c.funIntroFlightProgress(23) > .22, 'more than 22% of the path in the first third');
assert(1 - c.funIntroFlightProgress(46) < .51, 'the final third carries about 50%, not 75%, of the path');
for (let frame = 69; frame <= 168; frame++) {
    assert.equal(c.funIntroFlightProgress(frame), 1, 'hard stop, no overshoot');
    assert.equal(c.funIntroFlightSample(frame, 0), 386);
    assert.equal(c.funIntroFlightSample(frame, 1), 114);
}
assert.equal(c.funIntroFlightProgress(-6), 0);
for (const x of [92, 140, 240, 330, 386]) {
    const crossing = c.funIntroFlightFrameAtX(x);
    assert(Math.abs(c.funIntroFlightSample(crossing, 0) - x) < 1e-8, 'letters follow the moving light');
}

c.funStartupIntroStart();
assert.equal(c.self.startup_intro.frame, -6);
assert.equal(cues.length, 1);
for (let i = 0; i < 75; i++) tickIntro();
assert.equal(c.self.startup_intro.frame, 69, 'stop is 1.25 seconds after sound starts');
for (let i = 75; i < 173; i++) tickIntro();
assert.equal(c.self.startup_intro.active, true);
tickIntro(); assert.equal(c.self.startup_intro.active, false, 'six still frames plus 168 animation frames');
assert.equal(c.self.startup_intro.sound, -1);
c.funStartupIntroStart();
audioTicks = 75; c.funStartupIntroStep();
assert.equal(c.self.startup_intro.frame, 69, 'a stalled renderer still reaches the endpoint on the sound peak');
c.funStartupIntroFinish();

// Execute the real menu dispatcher: the skip press must never reach a button action.
const menuStep = `(function(){${translate(read('objects/oMenu/Step_0.gml'))}})()`;
for (const key of ['enter', 'space', 'escape', 'mouse']) {
    keys.clear(); clicked = false;
    c.self = {broken_menu: false, functions: [() => actions++], current_index: 0, immediate_actions: [true]};
    c.funStartupIntroStart(); const handle = c.self.startup_intro.sound;
    if (key === 'mouse') clicked = true; else keys.add(key);
    vm.runInContext(menuStep, c);
    assert.equal(c.self.startup_intro.active, false);
    assert.equal(stopped.at(-1), handle);
    assert.equal(c.self.mouse_allowed_counter, 10);
    assert.equal(actions, 0);
}
keys.clear(); clicked = false;
c.funStartupIntroStart(); const handle = c.self.startup_intro.sound;
vm.runInContext(translate(read('objects/oMenu/CleanUp_0.gml')), c);
assert.equal(stopped.at(-1), handle, 'leaving the menu stops only the intro voice');

c.global.sfx_enabled = false;
const before = cues.length;
c.funStartupIntroStart(); assert.equal(cues.length, before);
assert.equal(c.self.startup_intro.sound, -1);
for (let i = 0; i < 174; i++) tickIntro();
assert.equal(c.self.startup_intro.active, false, 'muting keeps the same animation timing');

const resource = JSON.parse(read('sounds/soundStartupIntro/soundStartupIntro.yy'));
assert.equal(resource.volume, 10 ** (-10/20), 'selected -10 dB relative to the preview');
assert.equal(resource.preload, true); assert.equal(resource.duration, 2.3);
assert.equal(resource.channelFormat, 1, 'stereo');
assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root, 'sounds/soundStartupIntro/soundStartupIntro.wav'))).digest('hex'),
    '520eae2b72764057ce4c18677a9d94a19c56d4e43671767e355dd8fd443d7c1e', 'exact approved N08-L PCM cue and gain');
assert(read('datafiles/AUDIO_CREDITS.txt').includes('hykenfreak'));

// Ordinary startup retains the intro; resumed endings bypass both its picture and sound.
let route;
Object.assign(c, {alarm: [], rMenu: 'menu', window_center() {}, room_goto: room => { route = room; },
    funOpenStoryEnding: real => { route = real ? 'true' : 'finale'; }});
for (const [stage, completed, expected] of [[0, false, 'menu'], [0, true, 'finale'], [1, true, 'true'], [2, true, 'menu']]) {
    Object.assign(c.global, {ending_stage: stage, special_level_completed: completed, startup_intro_pending: true});
    vm.runInContext(translate(read('objects/oLoading/Alarm_0.gml')), c);
    assert.equal(route, expected);
    assert.equal(c.global.startup_intro_pending, expected === 'menu');
}
console.log('PASS: approved cue, rising flight, exact endpoint/peak, predelay, menu timing, four skips, cleanup and muted launch.');
