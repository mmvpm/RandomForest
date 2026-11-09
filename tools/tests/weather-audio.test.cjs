/** Exercise actual persistent atmosphere ownership, twelve-second envelopes and accepted pools. */
'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'../../RandomForest'),catalog=JSON.parse(fs.readFileSync(path.join(root,'datafiles/weather_audio/catalog.json'),'utf8'));
let serial=0,peak=0,resumes=0,player=true,ambient=true,aiming=false,results=false,theme='night',story=false,ending=false;const assets=new Set(),voices=new Map();
const context=vm.createContext({self:{},global:{sfx_enabled:true,music_enabled:true,ending_stage:0,playing_level:0,current_level:0,menu_audio_theme:'night'},room:1,rMenu:0,rLevelSelect:2,rBlackRoom:3,oMenu:{startup_intro:{active:false}},oPlayer:'player',oAmbientSystem:'ambient',oTapController:'aim',oPauseMenu:{paused:false},oLevelPassing:'results',gamespeed_fps:60,
 game_get_speed:()=>60,get_timer:()=>42,funCurrentLevelTheme:()=>theme,funLevelTheme:()=>theme,
 funFindBlackRoomScene:()=>story?{}:undefined,funLevelTracksProgress:()=>true,funStoryEndingActive:()=>ending,
 variable_global_exists:k=>Object.hasOwn(context.global,k),
 instance_exists:o=>o==='player'?player:o==='ambient'?ambient:o==='aim'?aiming:o==='results'?results:o===context.oPauseMenu,
 array_length:a=>a.length,array_push:(a,v)=>a.push(v),floor:Math.floor,min:Math.min,max:Math.max,abs:Math.abs,string:String,
 clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,is_undefined:v=>v===undefined,
 variable_struct_get_names:Object.keys,variable_struct_get:(s,k)=>s[k],variable_struct_set:(s,k,v)=>s[k]=v,
 json_parse:JSON.parse,funReadGeneratedLevelFile:f=>fs.readFileSync(path.join(root,'datafiles',f),'utf8'),
 audio_create_stream(file){assert(fs.existsSync(path.join(root,'datafiles',file)));const id=++serial;assets.add(id);peak=Math.max(peak,assets.size);return id;},
 audio_sound_length:()=>60,audio_play_sound(asset,priority,loop){assert.equal(loop,true);const id=++serial;voices.set(id,{asset,gain:0,paused:false});return id;},
 audio_is_playing:id=>voices.has(id)&&!voices.get(id).paused,audio_is_paused:id=>voices.get(id)?.paused??false,
 audio_pause_sound:id=>voices.get(id).paused=true,audio_resume_sound:id=>{voices.get(id).paused=false;resumes++;},
 audio_sound_gain(id,gain,ms){assert.equal(ms,0);voices.get(id).gain=gain;},audio_stop_sound:id=>voices.delete(id),audio_destroy_stream:id=>assets.delete(id)
});
/** Translate only GML operators, keeping production functions unchanged. */
function load(name){vm.runInContext(fs.readFileSync(path.join(root,'scripts',name,name+'.gml'),'utf8').replace(/^#macro (\w+) (.+)$/gm,'const $1 = $2;').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||').replace(/\bmod\b/g,'%'),context);}
for(const name of ['scriptForestWeather','scriptAtmosphereMix','scriptAtmosphereDirector','scriptAtmosphereScene','scriptWeatherAudio'])load(name);
/** Advance actual weather and audio without wall-clock sleeping. */
function advance(frames){for(let i=0;i<frames;i++){context.funWeatherUpdate(context.global.forest_weather,1/60);context.funWeatherAudioStep();assert(assets.size<=(context.self.menu_tail?3:2));}}
/** Start one stable state in a fresh session owner. */
function begin(phase,lighting='night'){theme=lighting;context.funWeatherAudioCreate();context.global.forest_weather=context.funWeatherCreate(123,theme);context.funWeatherSetPhase(context.global.forest_weather,phase);context.global.forest_weather.rain=context.global.forest_weather.target_rain;advance(1);}
/** Assert the actual voice reaches its target in 60 ticks, with only one gain curve. */
function checkEntrance(label){
 for(let frame=1;frame<=60;frame++){
  advance(1);
  const stream=context.self.active;
  assert(stream,`${label}: entry must not inherit a quiet gap`);
  const target=stream.base_gain*context.self.volume*stream.scale;
  const progress=frame/60,expected=target*progress*progress*(3-2*progress);
  assert(Math.abs(voices.get(stream.voice).gain-expected)<1e-9,`${label}: gain at frame ${frame}`);
 }
 assert.equal(context.self.scene_gain,1,`${label}: full volume after one second`);
 assert.equal(context.self.outgoing,undefined,`${label}: no old weather tail left on entry`);
 assert.equal(context.self.mix_pending,undefined);
}
for(const [phase,lighting] of [['dry','day'],['dry','night'],['rain','night'],['storm','night'],['drips','night'],['fog','night']]){
 theme=lighting;context.funWeatherAudioCreate();
 context.global.forest_weather=context.funWeatherCreate(123,lighting);context.funWeatherSetPhase(context.global.forest_weather,phase);
 context.global.forest_weather.rain=context.global.forest_weather.target_rain;
 checkEntrance(`fresh ${phase}/${lighting}`);
 // A room change must preserve an unfinished weather mix and its two native voices.
 const items=catalog[lighting];context.funAtmosphereMixSelect(items[0],12);
 context.funAtmosphereMixSelect(items[1],12);context.funAtmosphereMixSelect(items[2],12);
 const pendingVoice=context.self.active.voice,pendingTail=context.self.outgoing.voice,pendingGain=context.self.scene_gain;
 context.funWeatherAudioEnterLevel();
 assert.equal(context.self.active.voice,pendingVoice);assert.equal(context.self.outgoing.voice,pendingTail);
 assert.equal(context.self.scene_gain,pendingGain);advance(1450);
 context.funWeatherAudioStop();
}
// A quiet gap belongs to the continuous forest, including a same-level retry.
begin('dry','day');advance(60);context.funAtmosphereMixSelect(undefined,12);
context.self.choices.day=0;context.self.remaining=20;context.self.was_silence=true;
const gapRemaining=context.self.remaining;
context.funWeatherAudioEnterLevel();advance(1);
assert.equal(context.self.choices.day,0);assert(context.self.remaining<=gapRemaining);context.funWeatherAudioStop();
for(const strength of ['rain','storm']){
 begin(strength);const rain=context.self.active.voice;advance(721);assert.equal(context.self.active.gain,strength==='rain'?.09:.12);
 context.funWeatherSetPhase(context.global.forest_weather,strength==='rain'?'storm':'rain');advance(721);assert.equal(context.self.active.voice,rain);
 const gain=context.self.active.gain;context.funWeatherSetPhase(context.global.forest_weather,'drips');advance(1);
 assert.equal(context.self.outgoing.voice,rain);assert(context.self.active.gain<.00001);
 const drip=context.self.active.voice;advance(359);assert(Math.abs(context.self.outgoing.gain-gain*.5)<.001);assert(Math.abs(context.self.active.gain-.045)<.001);
 assert(voices.has(rain),'rain tail stays alive halfway through long fade');advance(361);assert(!voices.has(rain));assert.equal(context.self.active.voice,drip);assert.equal(context.self.active.gain,.09);
 player=false;aiming=true;const stamp=serial;advance(30);assert.equal(context.self.active.voice,drip);assert.equal(serial,stamp);
 ambient=false;const elapsed=context.self.mix_elapsed;context.funWeatherAudioStep();assert(voices.get(drip).paused);assert.equal(context.self.mix_elapsed,elapsed);
 ambient=true;player=true;aiming=false;context.funWeatherAudioStep();assert(!voices.get(drip).paused);assert.equal(context.self.active.voice,drip);
 // The unchanged “Sounds” toggle controls actions independently of forest ambience.
 const beforeSfxMute=context.self.active.voice;
 context.global.sfx_enabled=false;context.funWeatherAudioStep();assert(voices.has(beforeSfxMute));
 context.global.sfx_enabled=true;
 context.global.music_enabled=false;context.funWeatherAudioStep();assert.equal(assets.size,0);context.global.music_enabled=true;
 context.funWeatherAudioStop();context.funWeatherAudioStop();assert.equal(voices.size,0);
}
begin('dry','morning');advance(721);const morning=context.self.active.voice,clock=context.self.remaining;
context.funWeatherSetPhase(context.global.forest_weather,'seeds');advance(60);assert.equal(context.self.active.voice,morning);assert(context.self.remaining<clock);
// Simulate a room restart with the same session and theme: no new handles or attack ramp.
const stamp=serial;context.funWeatherAudioStep();assert.equal(serial,stamp);
theme='evening';context.global.forest_weather.theme='evening';context.funWeatherSetPhase(context.global.forest_weather,'rain');advance(1);const outgoing=context.self.outgoing.voice;
context.funWeatherSetPhase(context.global.forest_weather,'drips');advance(1);assert(voices.has(outgoing));
context.funWeatherSetPhase(context.global.forest_weather,'dry');advance(1);assert.equal(context.self.mix_pending.item.file,catalog.evening[context.self.choices.evening-1].file);
advance(1450);assert.equal(context.self.active.track,catalog.evening[context.self.choices.evening-1].id);assert.equal(assets.size,1);
// Restore the exact portal envelope: fade for one second, then stay silent on results.
const portalVoice=context.self.active.voice,portalGain=voices.get(portalVoice).gain;
context.funWeatherAudioBeginPortalFade();
for(let frame=1;frame<=60;frame++){
 if(frame===20){results=true;ambient=false;player=false;}
 context.funWeatherAudioStep();
 const t=1-frame/60,expected=portalGain*t*t*(3-2*t);
 if(voices.has(portalVoice)){
  assert(!voices.get(portalVoice).paused,'results keep the outgoing tail playing');
  assert(Math.abs(voices.get(portalVoice).gain-expected)<1e-9,`original portal curve at frame ${frame}`);
 }
}
context.funWeatherAudioStep();assert.equal(assets.size,0);assert.equal(context.self.scene_gain,0);
const silentResultsSerial=serial;advance(120);assert.equal(serial,silentResultsSerial,'results never restart nature');
results=false;ambient=true;player=true;context.funWeatherAudioEnterLevel();
assert.equal(context.self.scene_gain,0);checkEntrance('results retry: original one-second entrance');
// Fast Next must immediately reset an unfinished exit, preserving the actual voice.
const quickVoice=context.self.active.voice;
context.funWeatherAudioBeginPortalFade();results=true;ambient=false;player=false;advance(10);
assert(voices.has(quickVoice));results=false;ambient=true;player=true;context.funWeatherAudioEnterLevel();
assert.equal(context.self.active.voice,quickVoice);assert.equal(voices.get(quickVoice).gain,0);
checkEntrance('fast Next: no extra mix or interface-volume ramp');
// An early portal completes its short exit without respawning audio before room change.
context.funWeatherAudioStop();context.funWeatherAudioEnterLevel();advance(3);
context.funWeatherAudioBeginPortalFade();advance(20);assert.equal(assets.size,0);
const earlySerial=serial;advance(30);assert.equal(serial,earlySerial);
context.funWeatherAudioEnterLevel();advance(750);
// Death and pause-menu retries keep the recording and any in-progress fade.
const deathVoice=context.self.active.voice,deathGain=voices.get(deathVoice).gain;
context.self.continue_after_death=true;context.funWeatherAudioEnterLevel();
assert.equal(context.self.active.voice,deathVoice);assert.equal(voices.get(deathVoice).gain,deathGain);
assert.equal(context.self.continue_after_death,false);
context.oPauseMenu.paused=true;context.funWeatherAudioStep();assert(voices.get(deathVoice).paused);
context.oPauseMenu.paused=false;context.funWeatherAudioEnterLevel();context.funWeatherAudioStep();
assert(!voices.get(deathVoice).paused);assert.equal(context.self.active.voice,deathVoice);
// Returning to the menu starts its clear forest without resuming gameplay recordings.
context.global.menu_audio_theme=theme;context.room=context.rMenu;context.funWeatherAudioStep();
advance(180);assert(!voices.has(deathVoice));assert.equal(context.self.scene_gain,1);
assert.equal(voices.get(context.self.active.voice).gain,context.self.active.gain*0.5,'menu forest is half the gameplay level');
const menuVoice=context.self.active.voice;
// Browsing is debounced; the latest page wins without three simultaneous streams.
context.room=context.rLevelSelect;context.global.menu_audio_theme='day';advance(10);
assert.equal(context.self.active.voice,menuVoice,'brief page visits do not start new recordings');
context.global.menu_audio_theme='night';advance(10);context.global.menu_audio_theme='morning';advance(10);
context.global.menu_audio_theme='day';advance(300);
assert.equal(context.self.audio_group,'day');assert(catalog.day.some(i=>i.id===context.self.active.track));
// Entering a different theme immediately overrides a pending menu page request.
context.global.menu_audio_theme='night';advance(5);theme='morning';
context.room=1;context.global.forest_weather.theme=theme;context.funWeatherSetPhase(context.global.forest_weather,'dry');
context.funWeatherAudioEnterLevel();advance(1);assert.equal(context.self.audio_group,'morning');
advance(300);assert(catalog.morning.some(i=>i.id===context.self.active.track));
// Cold startup waits for the approved title sound, then fades in its displayed forest.
context.funWeatherAudioStop();context.room=context.rMenu;context.global.menu_audio_theme='night';
context.oMenu.startup_intro.active=true;
const hasInstance=context.instance_exists;context.instance_exists=o=>o===context.oMenu||hasInstance(o);
advance(30);assert.equal(assets.size,0);
context.oMenu.startup_intro.active=false;advance(300);assert.equal(context.self.audio_group,'night');
// All story rooms are silent, including long conversations and both endings.
context.room=1;theme='night';context.global.forest_weather.theme=theme;context.funWeatherSetPhase(context.global.forest_weather,'dry');
context.funWeatherAudioEnterLevel();advance(300);story=true;
const storyVoice=context.self.active.voice;
context.funWeatherAudioBeginPortalFade();advance(10);context.room=context.rBlackRoom;ambient=false;
advance(180);assert(!voices.has(storyVoice));assert.equal(assets.size,0);
const silentSerial=serial;advance(60*300);assert.equal(serial,silentSerial,'long conversations never open background streams');
// Results after a conversation remain silent too; only opening a level restarts nature.
results=true;const storyResultsSerial=serial;advance(180);
assert.equal(assets.size,0);assert.equal(serial,storyResultsSerial);results=false;
// Both finale kinds and the broken menu contain neither drone nor nature.
for(const stage of [0,1]){
 ending=false;context.room=context.rBlackRoom;advance(180);assert.equal(assets.size,0);
 ending=true;advance(1);assert.equal(assets.size,0);advance(600);assert.equal(assets.size,0);
 context.room=context.rMenu;context.global.ending_stage=1;advance(120);assert.equal(assets.size,0);
 context.global.ending_stage=0;
}
ending=false;story=false;context.room=1;ambient=true;player=true;
context.funWeatherAudioEnterLevel();advance(750);
const held=context.self.active.voice;context.funAtmosphereMixSelect(undefined,12);
let lastGain=context.self.outgoing.gain;
for(let i=0;i<721;i++){context.funAtmosphereMixStep(1/60);if(context.self.outgoing){assert(context.self.outgoing.gain<=lastGain);lastGain=context.self.outgoing.gain;}}
assert(!voices.has(held));assert.equal(assets.size,0);context.funWeatherAudioStop();

/** Start a fresh menu over a stable weather session. */
function transitionMenu(phase='dry',lighting='night'){
 context.funWeatherAudioStop();context.self={};theme=lighting;player=false;ambient=false;aiming=false;results=false;
 context.room=context.rMenu;context.oPauseMenu.paused=false;context.oMenu.startup_intro.active=false;
 context.global.music_enabled=true;context.global.ending_stage=0;context.global.menu_audio_theme=lighting;
 context.funWeatherAudioCreate();context.global.forest_weather=context.funWeatherCreate(123,lighting);
 context.funWeatherSetPhase(context.global.forest_weather,phase,999999);
 context.global.forest_weather.rain=context.global.forest_weather.target_rain;
 context.global.forest_weather.fog=context.global.forest_weather.target_fog;advance(180);
}
/** Open gameplay through the real weather and audio entry callbacks. */
function transitionGame(lighting='night'){
 theme=lighting;context.room=1;player=true;ambient=true;results=false;aiming=false;context.oPauseMenu.paused=false;
 context.funWeatherApplyTheme(context.global.forest_weather,lighting);context.funWeatherAudioEnterLevel();
}
/** Capture playback values before production metadata changes. */
function transitionRecordings(){return [context.self.active,context.self.outgoing,context.self.menu_tail].filter(Boolean).map(s=>({voice:s.voice,gain:voices.get(s.voice).gain}));}
let transitionCases=0;
// Wet entries override every stage of a page change without waiting for its old goal.
for(const phase of ['rain','storm','drips','fog'])for(const browse of [0,1,23,24,25,40,90,150,180])for(const destination of ['night','evening']){
 transitionMenu(phase);if(browse){context.global.menu_audio_theme='evening';advance(browse);}
 const old=transitionRecordings();transitionGame(destination);
 for(let frame=1;frame<=60;frame++){
  advance(1);const active=context.self.active;
  assert(active&&catalog[phase].some(i=>i.id===active.track),`${phase}/${browse}: stale page before weather`);
  const t=frame/60,blend=t*t*(3-2*t),target=active.base_gain*active.scale;
  assert(Math.abs(voices.get(active.voice).gain-target*blend)<1e-9,`${phase}/${browse}: entrance frame ${frame}`);
  for(const s of old)if(voices.has(s.voice))assert(Math.abs(voices.get(s.voice).gain-s.gain*(1-blend))<1e-9,'menu recordings fade from actual output');
  assert.equal(context.self.mix_pending,undefined,'weather replaces the pending page');
 }
 advance(2);assert.equal(assets.size,1);assert.equal(context.self.menu_tail,undefined);transitionCases++;
}
// Two queued pages cannot postpone the new weather either.
transitionMenu('rain');context.global.menu_audio_theme='day';advance(40);context.global.menu_audio_theme='evening';advance(25);
assert(context.self.mix_pending);transitionGame('evening');advance(61);
assert.equal(context.self.active.track,'RAIN');assert.equal(context.self.active.gain,.09);assert.equal(assets.size,1);transitionCases++;
// Clear entries retain the recording and exact progress of an already accepted page fade.
for(const browse of [0,25,40,90,150]){
 transitionMenu();if(browse){context.global.menu_audio_theme='evening';advance(browse);}
 const active=context.self.active.voice,tail=context.self.outgoing?.voice,elapsed=context.self.mix_elapsed,duration=context.self.mix_duration,created=serial;
 transitionGame(browse?'evening':'night');advance(1);
 assert.equal(context.self.active.voice,active);assert.equal(context.self.outgoing?.voice,tail);assert.equal(serial,created);
 assert.equal(context.self.mix_duration,duration);assert(Math.abs(context.self.mix_elapsed-Math.min(duration,elapsed+1/60))<1e-9);
 advance(150);assert.equal(context.self.ui_gain,1);transitionCases++;
}
// Entering before debounce expires immediately requests the clear two-second fade.
for(const browse of [1,5,23,24]){
 transitionMenu();context.global.menu_audio_theme='evening';advance(browse);transitionGame('evening');advance(1);
 assert.equal(context.self.audio_group,'evening');assert.equal(context.self.mix_duration,2);advance(121);assert.equal(context.self.active.track,'E1');transitionCases++;
}
// A quiet gap may leave only an outgoing menu recording when weather starts.
transitionMenu('rain');context.self.choices.night=0;context.self.remaining=30;context.funAtmosphereMixSelect(undefined,2);advance(30);
transitionGame();advance(61);assert.equal(context.self.active.track,'RAIN');assert.equal(context.self.active.gain,.09);assert.equal(assets.size,1);transitionCases++;
// Pause -> menu never resumes gameplay, even during the three-recording entrance.
for(const phase of ['dry','fog','rain','storm','drips'])for(const progress of [1,15,59,90])for(const menuTheme of ['night','day']){
 transitionMenu(phase);context.global.menu_audio_theme='evening';advance(40);transitionGame();advance(progress);
 const old=transitionRecordings();context.oPauseMenu.paused=true;context.funWeatherAudioStep();
 for(const s of old)assert(voices.get(s.voice).paused);
 const resumed=resumes;context.room=context.rMenu;player=false;ambient=false;context.oPauseMenu.paused=false;context.global.menu_audio_theme=menuTheme;
 for(let frame=1;frame<=60;frame++){
  advance(1);assert.equal(resumes,resumed,'menu must not resume gameplay recordings');
  for(const s of old)assert(!voices.has(s.voice),'dispose old weather before menu playback');
  const active=context.self.active;assert(catalog[menuTheme].some(i=>i.id===active.track));
  const t=frame/60,expected=active.base_gain*.5*t*t*(3-2*t);
  assert(Math.abs(voices.get(active.voice).gain-expected)<1e-9,'menu enters for one second at half gain');
 }
 transitionCases++;
}
// Every interruption accounts for the extra menu tail and releases it exactly once.
for(const outcome of ['resume','retry','death','results-fast','results-late','mute','CK']){
 transitionMenu('rain');context.global.menu_audio_theme='evening';advance(40);transitionGame();advance(15);
 assert.equal(assets.size,3);const old=transitionRecordings(),elapsed=context.self.mix_elapsed;
 if(['resume','retry','death'].includes(outcome)){
  context.oPauseMenu.paused=true;context.funWeatherAudioStep();assert.equal(context.self.mix_elapsed,elapsed);
  for(const s of old)assert(voices.get(s.voice).paused);
  context.oPauseMenu.paused=false;
  if(outcome!=='resume'){context.self.continue_after_death=outcome==='death';transitionGame();}
  advance(1);assert.equal(assets.size,3);for(const s of old)assert(!voices.get(s.voice).paused);
  advance(61);assert.equal(assets.size,1);
 }else if(outcome.startsWith('results')){
  context.funWeatherAudioBeginPortalFade();results=true;player=false;ambient=false;advance(outcome==='results-fast'?10:80);
  transitionGame();checkEntrance(outcome);advance(1);assert.equal(assets.size,1);
 }else{
  if(outcome==='mute')context.global.music_enabled=false;
  else{context.room=context.rBlackRoom;player=false;ambient=false;}
  advance(1);assert.equal(assets.size,0);
 }
 transitionCases++;
}
context.funWeatherAudioStop();assert.equal(assets.size,0);assert.equal(voices.size,0);
console.log(`PASS: ${transitionCases} menu/game cases, one-second curves, clear continuity, pause routing and interruption cleanup`);
// The visible drizzle stays restrained while the unchanged twelve-second sound builds.
for(const lighting of ['evening','night'])for(const from of ['dry','fog'])for(const to of ['rain','storm']){
 context.funWeatherAudioStop();context.self={};theme=lighting;player=true;ambient=true;results=false;aiming=false;
 context.room=1;context.oPauseMenu.paused=false;context.global.music_enabled=true;context.funWeatherAudioCreate();
 const weather=context.funWeatherCreate(123,lighting);context.global.forest_weather=weather;
 context.funWeatherSetPhase(weather,from,999999);weather.rain=0;weather.fog=weather.target_fog;advance(90);
 context.funWeatherSetPhase(weather,to,999999);
 for(let frame=1;frame<=720;frame++){
  advance(1);const active=context.self.active,density=context.funWeatherRainDensity(weather);
  assert.equal(active.file,'rain.ogg');assert.equal(context.self.mix_duration,12);
  const expected=active.base_gain*active.scale*density;
  assert(voices.get(active.voice).gain+1e-9>=expected,`${lighting}/${from}/${to}: visual rain must not outrun the sound at frame ${frame}`);
  if(frame===720)assert(Math.abs(voices.get(active.voice).gain-expected)<1e-9,'steady density and sound meet at the end');
 }
 assert(Math.abs(weather.rain_onset-1)<1e-12);context.funWeatherAudioStop();
}
console.log('PASS: eight natural rain/storm transitions keep the first drizzle restrained and finish with the unchanged sound');
const approved={morning:['M1','M2','M3'],day:['D1','D3','DS3'],evening:['E1','E2','ES3'],night:['N1','N2','NS3','N4','N5'],fog:['F6','F7']};
for(const [group,ids] of Object.entries(approved))assert.deepEqual(catalog[group].map(i=>i.id),ids);
const report=[];
context.funWeatherAudioCreate();
for(const group of Object.keys(approved)){
 context.self.calm_runs=0;context.self.was_silence=false;context.self.last_source=-1;context.self.last_track='';let total=0,accents=0,gaps=0,last='';
 for(let i=0;i<4000;i++){
  context.funAtmosphereDirectorPick(group,i===0);const choice=context.self.choices[group],duration=context.self.remaining;total+=duration;
  if(choice===0){assert.notEqual(last,'silence');last='silence';gaps++;continue;}
  const item=catalog[group][choice-1];assert(item.weight>0);if(item.role==='accent')accents+=duration;last=item.id;
 }
 if(group==='fog')assert.equal(accents,0);
 report.push({group,accent_hold_pct:+(accents/total*100).toFixed(2),quiet_gaps:gaps});
 assert(gaps>0);if(group!=='fog')assert(accents/total<.08);
}
context.funWeatherAudioStop();assert.equal(assets.size,0);assert.equal(peak,3);
console.log('PASS: half-volume menus, original results transitions, live retries, silent story/endings, two normal streams plus one short menu tail, mute and cleanup');
console.log(JSON.stringify(report));
