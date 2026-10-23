/** Exercise production weather sound ownership, transitions, pause, mute and cleanup. */
'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'../../RandomForest');
let serial=0,peak=0,active=true;
const assets=new Set(),voices=new Map();
const context=vm.createContext({self:{},global:{sfx_enabled:true},oPlayer:'player',oAmbientSystem:'ambient',gamespeed_fps:60,
  game_get_speed:()=>60,instance_exists:()=>active,
  array_length:a=>a.length,array_push:(a,v)=>a.push(v),floor:Math.floor,min:Math.min,max:Math.max,
  clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,
  audio_create_stream(file){assert(fs.existsSync(path.join(root,'datafiles',file)));const id=++serial;assets.add(id);peak=Math.max(peak,assets.size);return id;},
  audio_play_sound(asset,priority,loop,gain){const id=++serial;voices.set(id,{asset,loop,gain,paused:false,ramps:[]});return id;},
  audio_is_playing:id=>voices.has(id)&&!voices.get(id).paused,audio_is_paused:id=>voices.get(id)?.paused??false,
  audio_pause_sound:id=>voices.get(id).paused=true,audio_resume_sound:id=>voices.get(id).paused=false,
  audio_sound_gain(id,gain,ms){voices.get(id).ramps.push({gain,ms});},
  audio_stop_sound:id=>voices.delete(id),audio_destroy_stream:id=>assets.delete(id)
});

/** Adapt GML operators while executing unchanged production functions. */
function load(name){vm.runInContext(fs.readFileSync(path.join(root,'scripts',name,name+'.gml'),'utf8').replace(/\band\b/g,'&&').replace(/\bor\b/g,'||').replace(/\bmod\b/g,'%'),context);}
load('scriptForestWeather');load('scriptWeatherAudio');

/** Advance one real weather tick, with the audio API represented by owned handles. */
function step(){context.funWeatherUpdate(context.global.forest_weather,1/60);context.funWeatherAudioStep();}

for(const strength of ['rain','storm']){
  context.funWeatherAudioCreate();const weather=context.funWeatherCreate(123,'night');context.global.forest_weather=weather;
  context.funWeatherSetPhase(weather,strength);weather.rain=weather.target_rain;context.funWeatherAudioStep();
  const rain=context.self.channels[0].voice;assert(voices.has(rain));
  context.funWeatherSetPhase(weather,strength==='rain'?'storm':'rain');weather.rain=weather.target_rain;context.funWeatherAudioStep();
  assert.equal(context.self.channels[0].voice,rain,'rain strength must preserve track position');
  context.funWeatherSetPhase(weather,'drips');let crossfade=-1;
  for(let frame=0;frame<1000;frame++){
    step();
    if(context.self.channels[1].voice!==-1&&crossfade<0){
      crossfade=frame;assert(context.funWeatherIsRaining(weather));assert(voices.has(rain));
      assert.equal(voices.get(rain).ramps.at(-1).ms,1200);assert.equal(voices.get(rain).ramps.at(-1).gain,0);
      assert.equal(voices.get(context.self.channels[1].voice).ramps.at(-1).gain,.09);
    }
    if(crossfade>=0&&frame===crossfade+90)assert(!voices.has(rain),'outgoing stream is released after fade');
  }
  assert(crossfade>=0&&crossfade<500);
  const drip=context.self.channels[1].voice;active=false;context.funWeatherAudioStep();assert(voices.get(drip).paused);
  active=true;context.funWeatherAudioStep();assert.equal(context.self.channels[1].voice,drip);assert(!voices.get(drip).paused);
  context.global.sfx_enabled=false;context.funWeatherAudioStep();assert.equal(voices.size,0);assert.equal(assets.size,0);
  context.global.sfx_enabled=true;context.funWeatherAudioStep();assert(context.self.channels[1].voice!==-1);
  context.funWeatherSetPhase(weather,'dry');weather.rain=0;
  for(let frame=0;frame<90;frame++)step();
  assert.equal(assets.size,0);context.funWeatherAudioStop();assert.equal(voices.size,0);
}
assert.equal(peak,2);
console.log('PASS: selected weather streams, continuous rain strength, 1.2s overlap, pause/resume, mute and asset cleanup');
