/** Exercise actual persistent atmosphere ownership, twelve-second envelopes and accepted pools. */
'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'../../RandomForest'),catalog=JSON.parse(fs.readFileSync(path.join(root,'datafiles/weather_audio/catalog.json'),'utf8'));
let serial=0,peak=0,player=true,ambient=true,aiming=false,theme='night';const assets=new Set(),voices=new Map();
const context=vm.createContext({self:{},global:{sfx_enabled:true},room:1,rMenu:0,oPlayer:'player',oAmbientSystem:'ambient',oTapController:'aim',gamespeed_fps:60,
 game_get_speed:()=>60,get_timer:()=>42,funCurrentLevelTheme:()=>theme,
 instance_exists:o=>o==='player'?player:o==='ambient'?ambient:o==='aim'?aiming:false,
 array_length:a=>a.length,array_push:(a,v)=>a.push(v),floor:Math.floor,min:Math.min,max:Math.max,abs:Math.abs,string:String,
 clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,is_undefined:v=>v===undefined,
 variable_struct_get_names:Object.keys,variable_struct_get:(s,k)=>s[k],variable_struct_set:(s,k,v)=>s[k]=v,
 json_parse:JSON.parse,funReadGeneratedLevelFile:f=>fs.readFileSync(path.join(root,'datafiles',f),'utf8'),
 audio_create_stream(file){assert(fs.existsSync(path.join(root,'datafiles',file)));const id=++serial;assets.add(id);peak=Math.max(peak,assets.size);return id;},
 audio_sound_length:()=>60,audio_play_sound(asset,priority,loop){assert.equal(loop,true);const id=++serial;voices.set(id,{asset,gain:0,paused:false});return id;},
 audio_is_playing:id=>voices.has(id)&&!voices.get(id).paused,audio_is_paused:id=>voices.get(id)?.paused??false,
 audio_pause_sound:id=>voices.get(id).paused=true,audio_resume_sound:id=>voices.get(id).paused=false,
 audio_sound_gain(id,gain,ms){assert.equal(ms,0);voices.get(id).gain=gain;},audio_stop_sound:id=>voices.delete(id),audio_destroy_stream:id=>assets.delete(id)
});
/** Translate only GML operators, keeping production functions unchanged. */
function load(name){vm.runInContext(fs.readFileSync(path.join(root,'scripts',name,name+'.gml'),'utf8').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||').replace(/\bmod\b/g,'%'),context);}
for(const name of ['scriptForestWeather','scriptAtmosphereMix','scriptAtmosphereDirector','scriptWeatherAudio'])load(name);
/** Advance actual weather and audio without wall-clock sleeping. */
function advance(frames){for(let i=0;i<frames;i++){context.funWeatherUpdate(context.global.forest_weather,1/60);context.funWeatherAudioStep();assert(assets.size<=2);}}
/** Start one stable state in a fresh session owner. */
function begin(phase,lighting='night'){theme=lighting;context.funWeatherAudioCreate();context.global.forest_weather=context.funWeatherCreate(123,theme);context.funWeatherSetPhase(context.global.forest_weather,phase);context.global.forest_weather.rain=context.global.forest_weather.target_rain;advance(1);}
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
 context.global.sfx_enabled=false;context.funWeatherAudioStep();assert.equal(assets.size,0);context.global.sfx_enabled=true;
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
const held=context.self.active.voice;context.funAtmosphereMixSelect(undefined,12);
let lastGain=context.self.outgoing.gain;
for(let i=0;i<721;i++){context.funAtmosphereMixStep(1/60);if(context.self.outgoing){assert(context.self.outgoing.gain<=lastGain);lastGain=context.self.outgoing.gain;}}
assert(!voices.has(held));assert.equal(assets.size,0);context.funWeatherAudioStop();
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
context.funWeatherAudioStop();assert.equal(assets.size,0);assert.equal(peak,2);
console.log('PASS: accepted production pools, 12s smooth overlap, rain strength continuity, restart/aim, menu pause, coalesced changes <=2 voices, mute and cleanup');
console.log(JSON.stringify(report));
